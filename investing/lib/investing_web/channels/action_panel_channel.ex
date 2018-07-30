defmodule InvestingWeb.ActionPanelChannel do
  @moduledoc """
  TODO:
  1. place order ( through OrderManager)
  """
  use InvestingWeb, :channel
  alias Investing.Finance
  alias Investing.Finance.CoinbaseServer
  alias Investing.Finance.StockServer

  def join(_, payload, socket) do
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

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (action_panel:lobby).
  def handle_in("symbol select", %{"old_symbol" => old_symbol, "new_symbol" => new_symbol, "market" => market}, socket) do
    # IO.puts ">>>>> symbol select triggered"

    # add symbol to server monitor list
    # in server: push "update_current_asset" down the websocket if there is change in price.
    if old_symbol|>String.length > 0, do: Finance.unsubscribe(old_symbol, self)
    Finance.subscribe(new_symbol, self)
    {:noreply, socket}
  end

  def handle_info({:price_updated, asset}, socket) do
    push(socket, "update_current_asset", asset)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
