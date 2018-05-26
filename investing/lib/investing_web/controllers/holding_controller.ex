defmodule InvestingWeb.HoldingController do
  use InvestingWeb, :controller

  alias Investing.Finance
  alias Investing.Finance.Holding

  action_fallback InvestingWeb.FallbackController

  def index(conn, _params) do
    holdings = Finance.list_holdings()
    render(conn, "index.json", holdings: holdings)
  end

  def create(conn, %{"holding" => holding_params}) do
    with {:ok, %Holding{} = holding} <- Finance.create_holding(holding_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", holding_path(conn, :show, holding))
      |> render("show.json", holding: holding)
    end
  end

  def show(conn, %{"id" => id}) do
    holding = Finance.get_holding!(id)
    render(conn, "show.json", holding: holding)
  end

  def update(conn, %{"id" => id, "holding" => holding_params}) do
    holding = Finance.get_holding!(id)

    with {:ok, %Holding{} = holding} <- Finance.update_holding(holding, holding_params) do
      render(conn, "show.json", holding: holding)
    end
  end

  def delete(conn, %{"id" => id}) do
    holding = Finance.get_holding!(id)
    with {:ok, %Holding{}} <- Finance.delete_holding(holding) do
      send_resp(conn, :no_content, "")
    end
  end
end
