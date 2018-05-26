defmodule InvestingWeb.HoldingControllerTest do
  use InvestingWeb.ConnCase

  alias Investing.Finance
  alias Investing.Finance.Holding

  @create_attrs %{bought_at: 120.5, quantity: 42, symbol: "some symbol"}
  @update_attrs %{bought_at: 456.7, quantity: 43, symbol: "some updated symbol"}
  @invalid_attrs %{bought_at: nil, quantity: nil, symbol: nil}

  def fixture(:holding) do
    {:ok, holding} = Finance.create_holding(@create_attrs)
    holding
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all holdings", %{conn: conn} do
      conn = get conn, holding_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create holding" do
    test "renders holding when data is valid", %{conn: conn} do
      conn = post conn, holding_path(conn, :create), holding: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, holding_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "bought_at" => 120.5,
        "quantity" => 42,
        "symbol" => "some symbol"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, holding_path(conn, :create), holding: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update holding" do
    setup [:create_holding]

    test "renders holding when data is valid", %{conn: conn, holding: %Holding{id: id} = holding} do
      conn = put conn, holding_path(conn, :update, holding), holding: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, holding_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "bought_at" => 456.7,
        "quantity" => 43,
        "symbol" => "some updated symbol"}
    end

    test "renders errors when data is invalid", %{conn: conn, holding: holding} do
      conn = put conn, holding_path(conn, :update, holding), holding: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete holding" do
    setup [:create_holding]

    test "deletes chosen holding", %{conn: conn, holding: holding} do
      conn = delete conn, holding_path(conn, :delete, holding)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, holding_path(conn, :show, holding)
      end
    end
  end

  defp create_holding(_) do
    holding = fixture(:holding)
    {:ok, holding: holding}
  end
end
