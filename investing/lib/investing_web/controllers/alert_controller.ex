defmodule InvestingWeb.AlertController do
  use InvestingWeb, :controller

  alias Investing.Finance
  alias Investing.Finance.Alert
  alias Investing.Finance.AlertNotifyServer

  action_fallback InvestingWeb.FallbackController

  def index(conn, %{"token" => token}) do

    # list alerts of user
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400) do
      alerts = Finance.list_alerts_of_user(user_id)
      render(conn, "index.json", alerts: alerts)
    end
  end

  def create(conn, %{"symbol" => symbol, "condition" => condition, "token" => token}) do
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400),
         {:ok, %Alert{} = alert} <- Finance.create_alert(%{symbol: symbol, condition: condition, user_id: user_id}) do

      AlertNotifyServer.reload_alerts()
      conn
      |> put_status(:created)
      |> put_resp_header("location", alert_path(conn, :show, alert))
      |> render("show.json", alert: alert)
    end
  end

  def show(conn, %{"id" => id}) do
    alert = Finance.get_alert!(id)
    render(conn, "show.json", alert: alert)
  end

  def delete(conn, %{"id" => id, "token" => token}) do
    alert = Finance.get_alert!(id)
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400),
         {:ok, %Alert{}} <- Finance.delete_alert(alert) do
      AlertNotifyServer.reload_alerts()
      send_resp(conn, :no_content, "")
    end
  end
end
