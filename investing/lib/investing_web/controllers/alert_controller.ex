defmodule InvestingWeb.AlertController do
  use InvestingWeb, :controller

  alias Investing.Finance
  alias Investing.Finance.Alert
  alias Investing.Finance.AlertManager

  action_fallback InvestingWeb.FallbackController

  def index(conn, %{"token" => token}) do

    # list alerts of user
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400) do
      alerts = Finance.list_alerts_of_user(user_id)
      render(conn, "index.json", alerts: alerts)
    end
  end

  def create(conn, %{"symbol" => symbol, "condition" => condition, "token" => token}) do
    require Logger
    Logger.info("creating alert")
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400),
         {:ok, %Alert{} = alert} <- Finance.create_alert(%{symbol: symbol, condition: condition, user_id: user_id}) do

      IO.inspect(alert, label: ">>>> adding alert in alert_controller: create()")
      AlertManager.add_alert(alert) # add new alert to alert manager
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

  @doc """
  Triggered by manually deleting an alert.

  WARNING
  needs to check if the alert is expired or not.
  If alert is still active, then it exists both in database and the alert service,
  therefore need to be removed in both places.
  Otherwise, simply remove it from database.
  """
  def delete(conn, %{"id" => id, "token" => token}) do
    alert = Finance.get_alert!(id)
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400),
         {:ok, %Alert{}} <- Finance.delete_alert(alert) do # remove from database
      # check expiration status of the alert, and need to delete it from alert manager if still active.

      IO.inspect(alert.expired, label: '>>>> is alert expired')
      if ! alert.expired do
        IO.puts ">>>> next step is to delete this active alert"
        AlertManager.del_alert(alert)
      end

      send_resp(conn, :no_content, "")
    end
  end
end
