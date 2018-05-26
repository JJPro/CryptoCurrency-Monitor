defmodule InvestingWeb.HoldingView do
  use InvestingWeb, :view
  alias InvestingWeb.HoldingView

  def render("index.json", %{holdings: holdings}) do
    %{data: render_many(holdings, HoldingView, "holding.json")}
  end

  def render("show.json", %{holding: holding}) do
    %{data: render_one(holding, HoldingView, "holding.json")}
  end

  def render("holding.json", %{holding: holding}) do
    %{id: holding.id,
      symbol: holding.symbol,
      bought_at: holding.bought_at,
      quantity: holding.quantity}
  end
end
