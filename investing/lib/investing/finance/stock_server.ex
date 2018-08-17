defmodule Investing.Finance.StockServer do
  use GenServer
  require Logger

# Public Interface:
  def start_link do
    result = GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    # IO.puts ">>>>> StockServer Started"
    Process.send(__MODULE__, :auto_update_stocks, [])
    # periodically (every 24 hours) pull down company directory data from iex and save to local database,
    # so that it will speed up company stock lookup
    # Process.send(__MODULE__, :daily_download_company_directory, [])
    result
  end

  def subscribe(symbol, channel) do
    # IO.puts ">>>>> subscribe to #{symbol}"
    GenServer.cast(__MODULE__, {:add_subscriber, {symbol, channel}})
  end

  def unsubscribe(symbol, channel) do
    # IO.puts ">>>>> unsubscribe to #{symbol}"
    GenServer.cast(__MODULE__, { :del_subscriber, {symbol, channel} } )
  end

  def batch_subscribe(symbols, channel) do
    GenServer.cast(__MODULE__, { :batch_subscribe, {symbols, channel} } )
  end

  def batch_unsubscribe(symbols, channel) do
    GenServer.cast(__MODULE__, { :batch_unsubscribe, {symbols, channel} } )
  end

  def unsubscribe_all(channel) do
    GenServer.cast(__MODULE__, { :del_subscriber_from_all, channel } )
  end


# GenServer Implementations

  def init(state) do
    # IO.puts ">>>>> Initializing StockServer"
    {:ok, state}
  end

  def terminate(_reason, state) do
    # IO.puts ">>>>> Terminating, reason: #{inspect reason}, state: #{inspect state}"
    {:shutdown, state}
  end


  def handle_info(:auto_update_stocks, state) do
    # fetch stock updates every 3 seconds,
    # check fetched price vs saved price,
    # if diff, send message to channel set of that symbol to update

    Process.send_after(__MODULE__, :auto_update_stocks, 4000)

    # Logger.info("state before auto_update: #{inspect state}")

    symbols = Map.keys(state)
    # fetch updates
    quotes = quotes_from_api(symbols) #|> IO.inspect(label: ">>>>>>>> quotes")
    state  = new_state_via_quotes(state, quotes)
    # Logger.info("state after auto_update: #{inspect state}")

    {:noreply, state}
  end

  @doc """
  Periodically (every 24 hours) pull down company directory data from iex and save to local database,
  Hence to speed up company stock lookup process in action-panel
  """
  def handle_info(:daily_download_company_directory, state) do
    Process.send_after(__MODULE__, :daily_download_company_directory, 1000*3600*24)

    {:noreply, state}
  end

  def handle_cast({ :add_subscriber, {symbol, channel} }, state) do
    new_state = if Map.has_key?(state, symbol) do
      with {price, channels} <- state[symbol] do
        Logger.info("channels: #{inspect channels}, \n channel: #{inspect channel}")
        %{state | symbol => {price, MapSet.put(channels, [channel: channel, new?: true])}}
      end
    else
      Map.put(state, symbol, {"--", MapSet.new([ [channel: channel, new?: true] ])})
    end
    {:noreply, new_state}
  end

  def handle_cast({ :del_subscriber, {symbol, channel} }, state) do
    new_state = with {price, channels} <- state[symbol] do
      %{state | symbol => {price, Enum.reject(channels, &(&1[:channel] == channel)) |> Enum.into(MapSet.new())}}
    end
    {:noreply, new_state}
  end

  def handle_cast({ :batch_subscribe, {symbols, channel} }, state) do
    new_state = Enum.reduce(
      symbols,
      state,
      fn (s, acc) ->
        if Map.has_key?(acc, s) do
          with {price, channels} <- acc[s] do
            %{acc | s => {price, MapSet.put(channels, [channel: channel, new?: true])}}
          end
        else
          Map.put(acc, s, {"--", MapSet.new([ [channel: channel, new?: true] ])})
        end
      end
    )
    {:noreply, new_state}
  end

  def handle_cast({ :batch_unsubscribe, {symbols, channel} }, state) do
    # remove channel from symbols' subscription list in state
    new_state = Enum.reduce(
      symbols,
      state,
      fn (s, acc) ->
        if Map.has_key?(acc, s) do
          with {price, channels} <- acc[s] do
            %{acc | s => {price, Enum.reject(channels, &(&1[:channel] == channel)) |> Enum.into(MapSet.new())}}
          end
        else
          acc
        end
      end
    )
    {:noreply, new_state}
  end

  def handle_cast({ :del_subscriber_from_all, channel }, state) do
    new_state =
      state
      |> Enum.map(fn {symbol, {price, channels}} ->
        {symbol, {price, Enum.reject(channels, &(&1[:channel] == channel)) |> Enum.into(MapSet.new())}}
      end)
      |> Enum.into(%{})
    {:noreply, new_state}
  end


  @spec quotes_from_api([bitstring]) :: {:ok, [Map]} | {:error, any}
  defp quotes_from_api([]), do: {:ok, []}
  defp quotes_from_api(symbols) do
    symbols_str = Enum.join(symbols, ",")
    apikey = "F66HDM3NGB6M7P9A"
    url = "https://www.alphavantage.co/query?function=BATCH_STOCK_QUOTES&symbols=#{symbols_str}&apikey=#{apikey}"

    with {:ok, resp} <- HTTPoison.get(url, [], timeout: :infinity) do
      quotes = resp #|> IO.inspect(label: ">>>>> response message")
               |> Map.get(:body) #|> IO.inspect(label: ">>>>>>>> response body")
               |> Poison.decode!() #|> IO.inspect(label: ">>>>>>>> response data")
               |> Map.get("Stock Quotes") #|> IO.inspect(label: ">>>>>> quotes")
      {:ok, quotes}
    end
  end

  defp new_state_via_quotes(state, {:error, _}) do
    broadcast_old_price_to_dirty_channels(state)
  end
  defp new_state_via_quotes(state, {:ok, nil}) do
    # Logger.info("API call throttling detected")
    broadcast_old_price_to_dirty_channels(state)
  end
  defp new_state_via_quotes(state, {:ok, quotes}) do
    # quotes is a list of JSON data maps,
    # a quote JSON data map example:
    #         %{
    #           "1. symbol" => "..",
    #           "2. price" => "float string",
    #           "3. volumn" => "int string",
    #           "4. timestamp" => "datetime string"
    #         }
    #
    # update the state object with prices from quotes,
    # and message pids if stored prices doesn't match with the quotes
    # quotes |> IO.inspect(label: ">>>>>> quotes")
    for old_entry = {symbol, {old_price, pids}} <- state, into: %{} do
      quote_price = Enum.find_value(quotes, fn
        %{"1. symbol" => ^symbol, "2. price" => price} -> price
        _                                              -> false
      end) # float | nil

      case quote_price do
        # didn't find in new quotes
        nil        -> broadcast_old_price_to_dirty_channels(old_entry)
        # found and price didn't change
        ^old_price -> broadcast_old_price_to_dirty_channels(old_entry)
        # found and price changed
        _          ->
          # broadcast to all channels and clear dirty flags
          pids_flags_cleared = Enum.map(pids, fn [channel: ch, new?: _] -> [channel: ch, new?: false] end)
                                |> Enum.into(MapSet.new())
          new_entry = {symbol, {quote_price, pids_flags_cleared}}
          broadcast_price(new_entry)
          new_entry
      end
    end
  end

  # Return: {symbol, {price, channels}} with dirty flags cleared on channels if price is not '--' (initial)
  defp broadcast_old_price_to_dirty_channels(entry = {_symbol, {price, _channels}}) when price == "--", do: entry
  defp broadcast_old_price_to_dirty_channels({symbol, {price, channels}}) do
    channels = Enum.map(channels, fn
      [channel: ch, new?: true] ->
        broadcast_price({symbol, {price, ch}})
        [channel: ch, new?: false]
      channel                   -> channel
    end)
    |> Enum.into(MapSet.new)

    {symbol, {price, channels}}
  end
  # Return: new state with dirty flags cleared on channels
  defp broadcast_old_price_to_dirty_channels(state) when is_map(state) do
    # check for new channels and broadcast old price if present
    Enum.map(state, &(broadcast_old_price_to_dirty_channels(&1)))
    |> Enum.into(%{})
  end

  @spec broadcast_price({String.t(), {String.t(), [pid()]|pid}}) :: :ok
  defp broadcast_price({symbol, {new_price, pid}}) when is_pid(pid) do
    msg = {
      :price_updated,
      %{symbol: symbol,
      price: new_price}
    }
    Process.alive?(pid) && Process.send(pid, msg, [])
  end
  defp broadcast_price({symbol, {new_price, pids}}) when is_map(pids) do
    msg = {
      :price_updated,
      %{symbol: symbol,
      price: new_price}
    }
    Enum.each(pids, fn [channel: pid, new?: _] ->
      is_pid(pid) && Process.alive?(pid) && Process.send(pid, msg, [])
    end)
  end
end
