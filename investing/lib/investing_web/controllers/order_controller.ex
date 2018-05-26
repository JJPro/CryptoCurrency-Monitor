defmodule InvestingWeb.OrderController do
  use InvestingWeb, :controller

  alias Investing.Finance
  alias Investing.Finance.Order

  action_fallback InvestingWeb.FallbackController

  def index(conn, _params) do
    orders = Finance.list_orders()
    render(conn, "index.json", orders: orders)
  end

  def create(conn, %{"order" => order_params}) do
    with {:ok, %Order{} = order} <- Finance.create_order(order_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", order_path(conn, :show, order))
      |> render("show.json", order: order)
    end
  end

  def show(conn, %{"id" => id}) do
    order = Finance.get_order!(id)
    render(conn, "show.json", order: order)
  end

  def update(conn, %{"id" => id, "order" => order_params}) do
    order = Finance.get_order!(id)

    with {:ok, %Order{} = order} <- Finance.update_order(order, order_params) do
      render(conn, "show.json", order: order)
    end
  end

  def delete(conn, %{"id" => id}) do
    order = Finance.get_order!(id)
    with {:ok, %Order{}} <- Finance.delete_order(order) do
      send_resp(conn, :no_content, "")
    end
  end
end
