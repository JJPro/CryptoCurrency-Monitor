defmodule Investing.TestServer do
  use WebSockex

## Interface
  def start_link do
    WebSockex.start_link("ws://tanks.jjpro.me/socket/websocket" |> IO.inspect(label: ">>>> connecting to:"), __MODULE__, %{}, name: __MODULE__)
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
    WebSockex.cast(__MODULE__, { :del_subscriber, {symbol, channel} } )
  end

  def send(msg) do
    IO.inspect(msg, label: ">>>>> sending frame")
    WebSockex.send_frame(__MODULE__, {:text, Poison.encode!(msg)})
    IO.puts ">>> message sent"
  end

## Callbacks
  def terminate(reason, state) do
    IO.puts("WebSockex for remote debbugging on port #{state.port} terminating with reason: #{inspect reason}")
    exit(:normal)
  end

  def handle_cast({ :add_subscriber, {symbol, channel} }, state) do
    IO.puts ">>> adding suscriber #{inspect channel}"
    # send subscribe event to gdax ticker
    send(%{
      type: "subscribe",
      product_ids: [symbol],
      channels: ["ticker"],
    })

    IO.puts ">>> subscribe message sent"

    # add channel to symbol's pub list in state
    new_state = if Map.has_key?(state, symbol) do
      %{state | symbol => MapSet.put(state[symbol], channel)}
    else
      Map.put(state, symbol, MapSet.new([channel]))
    end
     |> IO.inspect(label: ">>>>>> new state")
    {:ok, new_state}
  end

  def handle_cast({ :del_subscriber, {symbol, channel} }, state) do
    # send unsubscribe event to gdax ticker
    send(%{
      type: "unsubscribe",
      product_ids: [symbol],
      channels: ["ticker"],
    })

    # remove channel from symbol's pub list in state
    {:ok, %{state | symbol => MapSet.delete(state[symbol], channel)}}
  end

  @doc """
  handle_frame(frame, state :: term) ::
  {:ok, new_state} |
  {:reply, frame, new_state} |
  {:close, new_state} |
  {:close, close_frame, new_state} when new_state: term
  TODO:
  check state and broadcast to all channels of the received symbol update
  """
  def handle_frame({type, msg}, state) do
    data = Poison.decode!(msg)
    IO.inspect(data, label: "received message")
    {:ok, state}
  end

  ## invoked after a connection is established.
  # def handle_connect(conn, state) do
  #
  # end
end
