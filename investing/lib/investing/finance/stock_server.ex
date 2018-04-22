defmodule Investing.Finance.StockServer do
  use GenServer

# Public Interface:
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    IO.puts ">>>>> StockServer Started"
    Process.send(__MODULE__, :auto_update_stocks, [])
  end

  def subscribe(symbol, channel) do
    IO.puts ">>>>> subscribe to #{symbol}"
    GenServer.cast(__MODULE__, {:add_subscriber, {symbol, channel}})
  end

  def batch_subscribe(symbols, channel) do
    GenServer.cast(__MODULE__, { :batch_subscribe, {symbols, channel} } )
  end

  def unsubscribe(symbol, channel) do
    IO.puts ">>>>> unsubscribe to #{symbol}"
    GenServer.cast(__MODULE__, { :del_subscriber, {symbol, channel} } )
  end

  def unsubscribe_all(channel) do
    GenServer.cast(__MODULE__, { :del_subscriber_from_all, channel } )
  end


# GenServer Implementations

  def init(state) do
    IO.puts ">>>>> Initializing StockServer"
    {:ok, state}
  end

  def terminate(reason, state) do
    IO.puts ">>>>> Terminating, reason: #{inspect reason}, state: #{inspect state}"
    {:shutdown, state}
  end


  def handle_info(:auto_update_stocks, state) do
    # fetch stock updates every second,
    # check fetched price vs saved price,
    # if diff, send message to channel set of that symbol to update

    Process.send_after(__MODULE__, :auto_update_stocks, 1000)

    # fetch updates
    apikey = "F66HDM3NGB6M7P9A"
    symbols_str = state |> Map.keys |> Enum.join(",") |> IO.inspect(label: ">>>>> symbols_str")
    url = "https://www.alphavantage.co/query?function=BATCH_STOCK_QUOTES&symbols=#{symbols_str}&apikey=#{apikey}"

    if String.length(symbols_str) > 0 do
      quotes =
        HTTPoison.get!(url) |> IO.inspect(label: ">>>>>>>> API response")
        |> Map.get(:body) |> IO.inspect(label: ">>>>>>>> response body")
        |> Poison.decode!() |> IO.inspect(label: ">>>>>>>> response data")
        |> Map.get("Stock Quotes") |> IO.inspect(label: ">>>>>> quotes")

      # compares differences
      quotes |> Enum.each(fn q ->
        with symbol <- q["1. symbol"],
            {price, channels} <- state[symbol],
            new_price <- q["2. price"] do

          if price != new_price do
            state = %{state | symbol => {new_price, channels}}
            Enum.each(channels, fn channel ->
              msg = {
                :update_asset_price,
                %{symbol: symbol,
                  price: new_price}
              }
              is_pid(channel) && Process.alive?(channel) && Process.send(channel, msg, [])
            end)
          end
        end
      end)
    end
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

  def handle_cast({ :del_subscriber, {symbol, channel} }, state) do
    with {price, channels} <- state[symbol] do
      new_state = %{state | symbol => {price, MapSet.delete(channels, channel)}}
      {:noreply, new_state}
    end
  end

  def handle_cast({ :del_subscriber_from_all, channel }, state) do
    new_state =
      state
      |> Enum.map(fn {symbol, {price, channels}} ->
        {symbol, {price, MapSet.delete(channels, channel)}}
      end)
    {:noreply, new_state}
  end
end
