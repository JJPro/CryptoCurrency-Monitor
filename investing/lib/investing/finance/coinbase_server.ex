defmodule Investing.Finance.CoinbaseServer do
  use WebSockex

## Interface
  def start_link(state) do
    WebSockex.start_link("wss://ws-feed.gdax.com" |> IO.inspect(label: ">>>> connecting to:"), __MODULE__, state, name: __MODULE__)
    # WebSockex.start_link("ws://tanks.jjpro.me/socket/websocket" |> IO.inspect(label: ">>>> connecting to:"), __MODULE__, state, name: __MODULE__)
  end

  def send(msg) do
    WebSockex.send_frame(__MODULE__, {:text, Poison.encode!(msg)})
  end

## Callbacks
  def terminate(reason, state) do
    IO.puts("WebSockex for remote debbugging on port #{state.port} terminating with reason: #{inspect reason}")
    exit(:normal)
  end

  # @spec handle_frame(frame, state :: term) ::
  # {:ok, new_state} |
  # {:reply, frame, new_state} |
  # {:close, new_state} |
  # {:close, close_frame, new_state} when new_state: term
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
