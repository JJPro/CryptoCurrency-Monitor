defmodule InvestingWeb.ActionPanelChannel do
  use InvestingWeb, :channel
  alias Investing.Finance.CoinbaseServer
  alias Investing.Finance.StockServer

  def join(_, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (action_panel:lobby).
  def handle_in("symbol select", %{"old_symbol" => old_symbol, "new_symbol" => new_symbol, "market" => market, "token" => token}, socket) do
    IO.puts ">>>>> symbol select triggered"

    # add symbol to server monitor list
    # in server: push "update_current_asset" down the websocket if there is change in price.
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "auth token", token, max_age: 86400) do
      case market do
        "CryptoCurrency" ->
          if String.length(old_symbol) > 0, do: CoinbaseServer.unsubscribe(old_symbol, self)
          CoinbaseServer.subscribe( new_symbol, self )
        _ ->
          if String.length(old_symbol) > 0, do: StockServer.unsubscribe(old_symbol, self)
          StockServer.subscribe( new_symbol, self )
      end
    end

    {:noreply, socket |> IO.inspect(label: ">>>> inspecting socket")}
  end

  def handle_info({:update_asset_price, asset}, socket) do
    push(socket, "update_current_asset", asset)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(%{"token" => token}) do
    with {:ok, _} <- Phoenix.Token.verify(InvestingWeb.Endpoint, "auth token", token, max_age: 86400) do
      true
    else
      _ -> false
    end
  end
end
