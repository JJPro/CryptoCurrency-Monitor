defmodule Investing.Finance.CoinbaseServer do
  use WebSockex

## Interface
  def start_link do
    WebSockex.start_link("wss://ws-feed.gdax.com", __MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  add given channel to symbol's monitor list / state
  1. update the server state, add the channel to symbol's broadcast MapSet
  2. send frame to gdax server subscribing to ticker's update
  """
  def subscribe(symbol, channel) do
    # update server state, adding channel to symbol's broadcast MapSet
    WebSockex.cast(__MODULE__, { :add_subscriber, {symbol, channel} } )
  end

  def unsubscribe(symbol, channel) do
    # update server state, deleting channel from symbol's broadcast MapSet
    WebSockex.cast(__MODULE__, { :del_subscriber, {symbol, channel} } )
  end

  def batch_subscribe(symbols, channel) do
    WebSockex.cast(__MODULE__, { :batch_subscribe, {symbols, channel} } )
  end

  def batch_unsubscribe(symbols, channel) do
    WebSockex.cast(__MODULE__, { :batch_unsubscribe, {symbols, channel} } )
  end


  def unsubscribe_all(channel) do
    # remove channel from all subscription list
    WebSockex.cast(__MODULE__, { :del_subscriber_from_all, channel |> IO.inspect(label: ">>>>> unsub all symbols for channel") } )
  end

  defp encode_frame(msg) do
    {:text, Poison.encode!(msg)}
  end

## Callbacks
  def terminate(_reason, _state) do
    # IO.puts("WebSockex for remote debbugging on port #{state.port} terminating with reason: #{inspect reason}")
    exit(:normal)
  end

  def handle_cast({ :add_subscriber, {symbol, channel} }, state) do
    # IO.puts ">>>>> adding subscriber"
    # add channel to symbol's pub list in state
    if Map.has_key?(state, symbol) do
      {last_quote, pid_set} = state[symbol]
      new_state = %{state | symbol => {last_quote, MapSet.put(pid_set, channel)}}

      send_quote_to_channel(channel, symbol, last_quote)
      {:ok, new_state}
    else
      new_state = Map.put(state, symbol, {"--", MapSet.new([channel])})
      frame = encode_frame(
        %{
          type: "subscribe",
          product_ids: [symbol],
          channels: ["ticker"],
        })
      # send subscribe event to gdax ticker
      {:reply, frame, new_state}
    end
  end

  def handle_cast({ :batch_subscribe, {symbols, channel} }, state) do
    # add channel to symbol's pub list in state
    new_state = Enum.reduce(
      symbols,
      state,
      fn (symbol, acc) ->
        if Map.has_key?(acc, symbol) do
          {last_quote, pid_set} = state[symbol]
          send_quote_to_channel(channel, symbol, last_quote)
          %{acc | symbol => {last_quote, MapSet.put(pid_set, channel)}}
        else
          Map.put(acc, symbol, {"--", MapSet.new([channel])})
        end
      end
    )

    frame = encode_frame(
      %{
        type: "subscribe",
        product_ids: symbols,
        channels: ["ticker"],
      })

    # send subscribe event to gdax ticker
    {:reply, frame, new_state}
  end

  def handle_cast({ :batch_unsubscribe, {symbols, channel} }, state) do
    # remove channel from symbols' pub list in state
    {new_state, unsubs} = Enum.reduce(
      symbols,
      {state, []},
      fn (symbol, acc) ->
        with {state, unsubs} <- acc do
          if Map.has_key?(state, symbol) do
            {last_quote, pid_set} = state[symbol]
            new_pid_set = MapSet.delete(pid_set, channel)
            state = %{state | symbol => {last_quote, new_pid_set}}
            cond do
              Enum.empty?(new_pid_set) -> {state, [symbol | unsubs]}
              true -> {state, unsubs}
            end
          else
            {state, unsubs} # symbol is not in the subscription list, dont need to do anything
          end
        end
      end
    )

    # unsub the symbols which there are no residual subscribers
    frame = encode_frame(
      %{
        type: "unsubscribe",
        product_ids: unsubs,
        channels: ["ticker"],
      })

    # send subscribe event to gdax ticker
    {:reply, frame, new_state}
  end

  def handle_cast({ :del_subscriber, {symbol, channel} }, state) do
    # unsubscribe from gdax when no one is listening on given symbol
    {last_quote, pid_set} = state[symbol]
    new_pid_set = MapSet.delete(pid_set, channel)
    new_state = %{state | symbol => {last_quote, new_pid_set}}
    if Enum.count(new_pid_set) > 0 do
      # remove channel from symbol's pub list in state
      {:ok, new_state}
    else
      frame = encode_frame(%{
        type: "unsubscribe",
        product_ids: [symbol],
        channels: ["ticker"],
      })
      # send unsubscribe event to gdax ticker
      {:reply, frame, new_state}
    end
  end

  def handle_cast({ :del_subscriber_from_all, channel }, state) do
    if !Enum.any?(state, fn {_symbol, {_last_quote, pid_set}} -> Enum.member?(pid_set, channel) end) do
      IO.puts ">>>>> Deleting #{inspect channel} from "
      IO.inspect(state, label: ">>>>> subscribers")
    end

    # update state
    new_state =
      state
      |> Enum.map(fn {symbol, {last_quote, pid_set}} -> {symbol, {last_quote, MapSet.delete(pid_set, channel)}} end)
      |> Enum.into(%{})

    # unsubscribe from gdax when no one is listening on given symbol
    # loop through state and unsub from those whose set is empty, hence no subscribers
    empty_symbols =
      new_state
      # find subscritions where is empty in new_state but non-empty in original state
      |> Enum.filter(fn {symbol, {_, new_pid_set}} ->
        {_, old_pid_set} = state[symbol]
        Enum.empty?(new_pid_set) && !Enum.empty?(old_pid_set)
      end)
      # retrieve symbols from those subscriptions
      |> Enum.map(fn {symbol, _} -> symbol end)

    cond do
      !Enum.empty?(empty_symbols) ->
        frame = encode_frame(%{
          type: "unsubscribe",
          product_ids: empty_symbols,
          channels: ["ticker"],
        }) |> IO.inspect(label: ">>>>>>>>>>>> frame")
        {:reply, frame, new_state}
      true ->
        {:ok, new_state}
    end
  end

  @doc """
  handle_frame(frame, state :: term) ::
  {:ok, new_state} |
  {:reply, frame, new_state} |
  {:close, new_state} |
  {:close, close_frame, new_state} when new_state: term
  check state and broadcast to all channels of the received symbol update
  """
  def handle_frame({_type, msg}, state) do
    data = Poison.decode!(msg)
    # |> IO.inspect(label: "received message")

    if data["type"] == "ticker" do
      # IO.puts "============ recieved data"
      symbol = data["product_id"]

      {_, pid_set} = state[symbol]
      price = String.to_float(data["price"])
      Enum.each(pid_set, fn channel ->
        send_quote_to_channel(channel, symbol, price)
      end)
      {:ok, %{state | symbol => {price, pid_set}}}
    else
      {:ok, state}
    end

  end

  defp send_quote_to_channel(channel_pid, symbol, price)
  when is_pid(channel_pid) and is_float(price) do
    msg = { :price_updated, %{symbol: symbol, price: price} }

    Process.alive?(channel_pid) && Process.send(channel_pid, msg, [])
  end

  ## invoked after a connection is established.
  # def handle_connect(conn, state) do
  #
  # end
end
