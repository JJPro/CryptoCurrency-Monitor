defmodule InvestingWeb.ActionPanelChannel do
  @moduledoc """
  """
  use InvestingWeb, :channel
  alias Investing.Finance
  alias Investing.Finance.OrderManager
  alias Investing.Finance.AlertManager
  alias Investing.Accounts
  require Logger

  def join("action_panel:"<>uid, payload, socket) do
    if authorized?(payload) do
      socket = assign(socket, :uid, String.to_integer(uid))       # attach uid with socket
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def terminate(_msg, _socket) do
    Finance.unsubscribe_all(self())
    {:shutdown, :closed}
  end

  def handle_in("symbol select", %{"old_symbol" => old_symbol, "new_symbol" => new_symbol, "market" => _market}, socket) do
    # IO.puts ">>>>> symbol select triggered"

    # add symbol to server monitor list
    # in server: push "update_current_asset" down the websocket if there is change in price.
    if old_symbol|>String.length > 0, do: Finance.unsubscribe(old_symbol, self())
    Finance.subscribe(new_symbol, self())
    {:noreply, socket}
  end

  def handle_in("place order", order, socket) do
    Logger.info("placing order, #{inspect order}")
    order =
      order
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.put(:user_id, socket.assigns.uid)
    OrderManager.place_order(order)
    {:noreply, socket}
  end

  def handle_in("create alert", alert, socket) do
    Logger.info("creating alert, #{inspect alert}")
    alert =
      alert
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.put(:user_id, socket.assigns.uid)
    AlertManager.create_alert(alert)
    {:noreply, socket}
  end

  def handle_in("get balance", _, socket) do
    {total, usable} = Finance.get_user_balances(socket.assigns.uid);

    # Logger.info("user's balance is {total: #{total}, usable: #{usable}}")
    {:reply, {:ok, %{total: total, usable: usable}}, socket}
  end

  def handle_in("get holdings", _, socket) do
    user = Accounts.get_user!(socket.assigns.uid) |> Investing.Repo.preload(:holdings)
    holdings = user.holdings
    # Logger.info("user #{user.username}'s holdings: #{inspect holdings}")
    {:reply, {:ok, %{holdings: holdings}}, socket}
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
