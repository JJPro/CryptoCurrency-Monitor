defmodule InvestingWeb.AlertChannel do
  use InvestingWeb, :channel
  alias Investing.Finance
  alias Investing.Finance.AlertManager

  def join("alert:"<>uid, payload, socket) do
    if authorized?(payload) do
      socket = assign(socket, :uid, String.to_integer(uid))       # attach uid with socket

      send(self(), :request_live_quotes_for_existing_alerts)
      send(self(), :list_alerts)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def terminate(_msg, _socket) do
    # IO.inspect(self(), label: ">>>>> alert channel pid")
    Finance.unsubscribe_all(self())
    {:shutdown, :closed}
  end

  def handle_info(:request_live_quotes_for_existing_alerts, socket) do
    active_symbols = for alert <- Finance.list_active_alerts_of_user(socket.assigns.uid), into: MapSet.new() do
      alert.symbol
    end # use MapSet to ensure uniqueness
    |> Enum.into([]) # convert back to list to pass to next function call

    Finance.batch_subscribe(active_symbols, self())

    {:noreply, socket}
  end

  def handle_info(:list_alerts, socket) do
    alerts = Finance.list_alerts_of_user(socket.assigns.uid)

    active_alerts = Enum.filter(alerts, &(!&1.expired))
    inactive_alerts = alerts -- active_alerts

    push(socket, "init alert list", %{
      active: active_alerts,
      inactive: inactive_alerts
    })

    {:noreply, socket}
  end

  def handle_info({:price_updated, data}, socket) do
    # IO.puts ">>>>>> received update"
    push(socket, "price updated", data)
    {:noreply, socket}
  end

  def handle_info({:subscribe_symbol, symbol}, socket) do
    Finance.subscribe(symbol, self())
    {:noreply, socket}
  end

  def handle_info({:unsubscribe_symbol, symbol}, socket) do
    Finance.unsubscribe(symbol, self())
    {:noreply, socket}
  end

  def handle_in("delete alert", %{"alert_id" => alert_id}, socket) do
    alert_id
    |> Finance.get_alert!()
    |> AlertManager.delete_alert()

    # Broadcasting is taken care of by AlertManager, nothing to do here.

    {:reply, :ok, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
