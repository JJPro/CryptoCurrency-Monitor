defmodule Investing.Finance.CoinbaseServer do
  use WebSockex

## Interface
  def start_link do
    WebSockex.start_link("wss://ws-feed.gdax.com" |> IO.inspect(label: ">>>> connecting to:"), __MODULE__, %{}, name: __MODULE__)
    # WebSockex.start_link("ws://tanks.jjpro.me/socket/websocket" |> IO.inspect(label: ">>>> connecting to:"), __MODULE__, state, name: __MODULE__)
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

  def batch_subscribe(symbols, channel) do
    WebSockex.cast(__MODULE__, { :batch_subscribe, {symbols, channel} } )
  end

  def unsubscribe(symbol, channel) do
    # update server state, deleting channel from symbol's broadcast MapSet
    WebSockex.cast(__MODULE__, { :del_subscriber, {symbol |> IO.inspect(label: "unsubscribing"), channel} } )
  end

  def unsubscribe_all(channel) do
    # remove channel from all subscription list
    WebSockex.cast(__MODULE__, { :del_subscriber_from_all, channel } )
  end

  @doc """
  manually send msg, for testing purpose only
  """
  def send(msg) do
    WebSockex.send_frame(__MODULE__, {:text, Poison.encode!(msg)})
  end

  defp encode_frame(msg) do
    {:text, Poison.encode!(msg)}
  end

## Callbacks
  def terminate(reason, state) do
    IO.puts("WebSockex for remote debbugging on port #{state.port} terminating with reason: #{inspect reason}")
    exit(:normal)
  end

  def handle_cast({ :add_subscriber, {symbol, channel} }, state) do
    # add channel to symbol's pub list in state
    if Map.has_key?(state, symbol) do
      new_state = %{state | symbol => MapSet.put(state[symbol], channel)}
      {:ok, new_state}
    else
      new_state = Map.put(state, symbol, MapSet.new([channel]))
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
          %{acc | symbol => MapSet.put(acc[symbol], channel)}
        else
          Map.put(acc, symbol, MapSet.new([channel]))
        end
      end
    )

    frame = encode_frame(
      %{
        type: "subscribe",
        product_ids: symbols,
        channels: ["ticker"],
      }) |> IO.inspect(label: "========= frame being sent ======== ")

    # send subscribe event to gdax ticker
    {:reply, frame, new_state}
  end

  def handle_cast({ :del_subscriber, {symbol, channel} }, state) do
    # unsubscribe from gdax when no one is listening on given symbol
    new_channel_set = MapSet.delete(state[symbol], channel)
    new_state = %{state | symbol => new_channel_set}
    if Enum.count(new_channel_set) > 0 do
      # remove channel from symbol's pub list in state
      {:ok, new_state}
    else
      frame = encode_frame(%{
        type: "unsubscribe",
        product_ids: [symbol],
        channels: ["ticker"],
      })
      # send unsubscribe event to gdax ticker
      {:ok, frame, new_state}
    end

  end

  def handle_cast({ :del_subscriber_from_all, channel }, state) do
    IO.puts ">>>>> removing channel #{inspect channel} from all subscription lists"

    # update state
    new_state =
      state
      |> Enum.map(fn {symbol, set} -> {symbol, MapSet.delete(set, channel)} end)

    # unsubscribe from gdax when no one is listening on given symbol
    # loop through state and unsub from those whose set is empty, hence no subscribers
    empty_symbols =
      state
      |> Enum.filter(fn {symbol, set} -> Enum.empty?(set) end)
      |> Map.keys

    if length(empty_symbols) > 0 do
      frame = encode_frame(%{
        type: "unsubscribe",
        product_ids: empty_symbols,
        channels: ["ticker"],
      })
      {:ok, frame, new_state}
    else
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
  def handle_frame({type, msg}, state) do
    data = Poison.decode!(msg)
    # |> IO.inspect(label: "received message")

    if data["type"] == "ticker" do
      # IO.puts "============ recieved data"

      channels = state[data["product_id"]]
      # |> IO.inspect(label: "========= channel list")
      |> Enum.each( fn channel ->
        msg = {
          :update_asset_price,
          %{symbol: data["product_id"],
            price: data["price"]}
        }

        is_pid(channel) && Process.alive?(channel) && Process.send(channel, msg, [])
       end)
    end

    {:ok, state}
  end

  ## invoked after a connection is established.
  # def handle_connect(conn, state) do
  #
  # end
end
