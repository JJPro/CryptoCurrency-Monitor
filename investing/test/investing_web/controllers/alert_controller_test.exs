defmodule InvestingWeb.AlertControllerTest do
  use InvestingWeb.ConnCase

  alias Investing.Finance
  alias Investing.Finance.Alert

  @create_attrs %{condition: "some condition", symbol: "some symbol"}
  @update_attrs %{condition: "some updated condition", symbol: "some updated symbol"}
  @invalid_attrs %{condition: nil, symbol: nil}

  def fixture(:alert) do
    {:ok, alert} = Finance.create_alert(@create_attrs)
    alert
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all alerts", %{conn: conn} do
      conn = get conn, alert_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create alert" do
    test "renders alert when data is valid", %{conn: conn} do
      conn = post conn, alert_path(conn, :create), alert: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, alert_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "condition" => "some condition",
        "symbol" => "some symbol"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, alert_path(conn, :create), alert: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update alert" do
    setup [:create_alert]

    test "renders alert when data is valid", %{conn: conn, alert: %Alert{id: id} = alert} do
      conn = put conn, alert_path(conn, :update, alert), alert: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, alert_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "condition" => "some updated condition",
        "symbol" => "some updated symbol"}
    end

    test "renders errors when data is invalid", %{conn: conn, alert: alert} do
      conn = put conn, alert_path(conn, :update, alert), alert: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete alert" do
    setup [:create_alert]

    test "deletes chosen alert", %{conn: conn, alert: alert} do
      conn = delete conn, alert_path(conn, :delete, alert)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, alert_path(conn, :show, alert)
      end
    end
  end

  defp create_alert(_) do
    alert = fixture(:alert)
    {:ok, alert: alert}
  end
end
