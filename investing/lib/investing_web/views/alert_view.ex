defmodule InvestingWeb.AlertView do
  use InvestingWeb, :view
  alias InvestingWeb.AlertView

  def render("index.json", %{alerts: alerts}) do
    %{data: render_many(alerts, AlertView, "alert.json")}
  end

  def render("show.json", %{alert: alert}) do
    %{data: render_one(alert, AlertView, "alert.json")}
  end

  def render("alert.json", %{alert: alert}) do
    %{id: alert.id,
      symbol: alert.symbol,
      condition: alert.condition,
      expired: alert.expired
    }
  end
end
