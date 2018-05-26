defmodule InvestingWeb.OrderView do
  use InvestingWeb, :view
  alias InvestingWeb.OrderView

  def render("index.json", %{orders: orders}) do
    %{data: render_many(orders, OrderView, "order.json")}
  end

  def render("show.json", %{order: order}) do
    %{data: render_one(order, OrderView, "order.json")}
  end

  def render("order.json", %{order: order}) do
    %{id: order.id,
      symbol: order.symbol,
      action: order.action,
      target: order.target,
      quantity: order.quantity,
      stoploss: order.stoploss,
      expired: order.expired}
  end
end
