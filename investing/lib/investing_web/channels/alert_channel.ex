defmodule InvestingWeb.AlertChannel do
  use InvestingWeb, :channel
  alias Investing.Finance

  def join("alert:"<>_, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def terminate(msg, socket) do
    IO.inspect(self, label: ">>>>> alert channel pid")
    Finance.unsubscribe_all(self)
    {:shutdown, :closed}
  end

  def handle_in("batch_subscribe", %{"token" => token, "alerts" => alerts}, socket) do
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "auth token", token, max_age: 86400) do
      # IO.inspect(alerts, label: "================= batch sub alerts =========\n")
      alerts
      |> Enum.map(fn a -> a["symbol"] end)
      |> Finance.batch_subscribe(self)
    end
    {:noreply, socket}
  end

  def handle_in("unsubscribe", %{"token" => token, "alert" => alert}, socket) do
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "auth token", token, max_age: 86400) do
      # IO.inspect(alert, label: ">>>>>>>  unsub alert")
      Finance.unsubscribe(alert["symbol"], self);
    end
    {:noreply, socket}
  end

  def handle_info({:price_updated, data}, socket) do
    # IO.puts ">>>>>> received update"
    push(socket, "update_asset_price", data)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
