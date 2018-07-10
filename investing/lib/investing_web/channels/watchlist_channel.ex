defmodule InvestingWeb.WatchlistChannel do
  use InvestingWeb, :channel
  alias Investing.Finance.CoinbaseServer
  alias Investing.Finance.StockServer
  alias Investing.Finance

  def join("watchlist:"<>token, payload, socket) do
    # IO.puts ">>>>>> socket joining"
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def terminate(msg, socket) do
    Finance.unsubscribe_all(self)
    {:shutdown, :closed}
  end

  # # Channels can be used in a request/response fashion
  # # by sending replies to requests from the client
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end

  def handle_in("subscribe", %{"token" => token, "asset" => asset}, socket) do
    # IO.puts "+++++++++++++++ received request for subscription"
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "auth token", token, max_age: 86400) do
      # IO.inspect(asset, label: "================= asset =========\n")
      Finance.subscribe(asset["symbol"], self)
    end
    {:noreply, socket}
  end

  def handle_in("batch_subscribe", %{"token" => token, "assets" => assets}, socket) do
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "auth token", token, max_age: 86400) do
      # IO.inspect(asset, label: "================= asset =========\n")
      symbols = assets |> Enum.map(fn a -> a["symbol"] end)
      Finance.batch_subscribe(symbols, self)
    end
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (watchlist:lobby).
  def handle_in("unsubscribe", %{"token" => token, "asset" => asset}, socket) do
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "auth token", token, max_age: 86400) do
      # IO.inspect(asset, label: "================= asset =========\n")
      Finance.unsubscribe(asset["symbol"], self);
    end
    {:noreply, socket}
  end

  def handle_info({:price_updated, asset}, socket) do
    # IO.puts ">>>>>> received update"
    push(socket, "update_asset_price", asset)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
