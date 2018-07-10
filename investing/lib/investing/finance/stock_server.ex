defmodule Investing.Finance.StockServer do
  use GenServer

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

  def terminate(reason, state) do
    # IO.puts ">>>>> Terminating, reason: #{inspect reason}, state: #{inspect state}"
    {:shutdown, state}
  end


  def handle_info(:auto_update_stocks, state) do
    # fetch stock updates every 3 seconds,
    # check fetched price vs saved price,
    # if diff, send message to channel set of that symbol to update

    Process.send_after(__MODULE__, :auto_update_stocks, 4000)

    # fetch updates
    symbols_str = state |> Map.keys |> Enum.join(",") #|> IO.inspect(label: ">>>>> symbols_str")
    apikey = "F66HDM3NGB6M7P9A"
    url = "https://www.alphavantage.co/query?function=BATCH_STOCK_QUOTES&symbols=#{symbols_str}&apikey=#{apikey}"

    if String.length(symbols_str) > 0 do
      quotes =
        with {:ok, resp} <- HTTPoison.get(url, [], timeout: :infinity) do
          resp
          |> Map.get(:body) #|> IO.inspect(label: ">>>>>>>> response body")
          |> Poison.decode!() #|> IO.inspect(label: ">>>>>>>> response data")
          |> Map.get("Stock Quotes") #|> IO.inspect(label: ">>>>>> quotes")
        else
          {:error, _} -> nil
        end

      # compares differences
      if quotes do
        quotes |> Enum.each(fn q ->
          symbol = q["1. symbol"]
          {price, channels} = state[symbol]
          new_price = q["2. price"]

          if price != new_price do
            state = %{state | symbol => {new_price, channels}}
            Enum.each(channels, fn channel ->
              msg = {
                :price_updated,
                %{symbol: symbol,
                price: new_price}
              }
              is_pid(channel) && Process.alive?(channel) && Process.send(channel, msg, [])
            end)
          end
        end)
      end
    end
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
        %{state | symbol => {price, MapSet.put(channels, channel)}}
      end
    else
      Map.put(state, symbol, {"--", MapSet.new([channel])})
    end
    {:noreply, new_state}
  end

  def handle_cast({ :del_subscriber, {symbol, channel} }, state) do
    new_state = with {price, channels} <- state[symbol] do
      %{state | symbol => {price, MapSet.delete(channels, channel)}}
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
            %{acc | s => {price, MapSet.put(channels, channel)}}
          end
        else
          Map.put(acc, s, {"--", MapSet.new([channel])})
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
            %{acc | s => {price, MapSet.delete(channels, channel)}}
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
        {symbol, {price, MapSet.delete(channels, channel)}}
      end)
      |> Enum.into(%{})
    {:noreply, new_state}
  end
end
