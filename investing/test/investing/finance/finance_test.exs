defmodule Investing.FinanceTest do
  use Investing.DataCase

  alias Investing.Finance

  describe "assets" do
    alias Investing.Finance.Asset

    @valid_attrs %{market: "some market", symbol: "some symbol"}
    @update_attrs %{market: "some updated market", symbol: "some updated symbol"}
    @invalid_attrs %{market: nil, symbol: nil}

    def asset_fixture(attrs \\ %{}) do
      {:ok, asset} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Finance.create_asset()

      asset
    end

    test "list_assets/0 returns all assets" do
      asset = asset_fixture()
      assert Finance.list_assets() == [asset]
    end

    test "get_asset!/1 returns the asset with given id" do
      asset = asset_fixture()
      assert Finance.get_asset!(asset.id) == asset
    end

    test "create_asset/1 with valid data creates a asset" do
      assert {:ok, %Asset{} = asset} = Finance.create_asset(@valid_attrs)
      assert asset.market == "some market"
      assert asset.symbol == "some symbol"
    end

    test "create_asset/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Finance.create_asset(@invalid_attrs)
    end

    test "update_asset/2 with valid data updates the asset" do
      asset = asset_fixture()
      assert {:ok, asset} = Finance.update_asset(asset, @update_attrs)
      assert %Asset{} = asset
      assert asset.market == "some updated market"
      assert asset.symbol == "some updated symbol"
    end

    test "update_asset/2 with invalid data returns error changeset" do
      asset = asset_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.update_asset(asset, @invalid_attrs)
      assert asset == Finance.get_asset!(asset.id)
    end

    test "delete_asset/1 deletes the asset" do
      asset = asset_fixture()
      assert {:ok, %Asset{}} = Finance.delete_asset(asset)
      assert_raise Ecto.NoResultsError, fn -> Finance.get_asset!(asset.id) end
    end

    test "change_asset/1 returns a asset changeset" do
      asset = asset_fixture()
      assert %Ecto.Changeset{} = Finance.change_asset(asset)
    end
  end

  describe "alerts" do
    alias Investing.Finance.Alert

    @valid_attrs %{condition: "some condition", symbol: "some symbol"}
    @update_attrs %{condition: "some updated condition", symbol: "some updated symbol"}
    @invalid_attrs %{condition: nil, symbol: nil}

    def alert_fixture(attrs \\ %{}) do
      {:ok, alert} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Finance.create_alert()

      alert
    end

    test "list_alerts/0 returns all alerts" do
      alert = alert_fixture()
      assert Finance.list_alerts() == [alert]
    end

    test "get_alert!/1 returns the alert with given id" do
      alert = alert_fixture()
      assert Finance.get_alert!(alert.id) == alert
    end

    test "create_alert/1 with valid data creates a alert" do
      assert {:ok, %Alert{} = alert} = Finance.create_alert(@valid_attrs)
      assert alert.condition == "some condition"
      assert alert.symbol == "some symbol"
    end

    test "create_alert/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Finance.create_alert(@invalid_attrs)
    end

    test "update_alert/2 with valid data updates the alert" do
      alert = alert_fixture()
      assert {:ok, alert} = Finance.update_alert(alert, @update_attrs)
      assert %Alert{} = alert
      assert alert.condition == "some updated condition"
      assert alert.symbol == "some updated symbol"
    end

    test "update_alert/2 with invalid data returns error changeset" do
      alert = alert_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.update_alert(alert, @invalid_attrs)
      assert alert == Finance.get_alert!(alert.id)
    end

    test "delete_alert/1 deletes the alert" do
      alert = alert_fixture()
      assert {:ok, %Alert{}} = Finance.delete_alert(alert)
      assert_raise Ecto.NoResultsError, fn -> Finance.get_alert!(alert.id) end
    end

    test "change_alert/1 returns a alert changeset" do
      alert = alert_fixture()
      assert %Ecto.Changeset{} = Finance.change_alert(alert)
    end
  end

  describe "orders" do
    alias Investing.Finance.Order

    @valid_attrs %{action: "some action", status: "executed", quantity: 42, stoploss: 120.5, symbol: "some symbol", target: 120.5}
    @update_attrs %{action: "some updated action", status: "pending", quantity: 43, stoploss: 456.7, symbol: "some updated symbol", target: 456.7}
    @invalid_attrs %{action: nil, status: nil, quantity: nil, stoploss: nil, symbol: nil, target: nil}

    def order_fixture(attrs \\ %{}) do
      {:ok, order} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Finance.create_order()

      order
    end

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Finance.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Finance.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      assert {:ok, %Order{} = order} = Finance.create_order(@valid_attrs)
      assert order.action == "some action"
      assert order.status == "executed"
      assert order.quantity == 42
      assert order.stoploss == 120.5
      assert order.symbol == "some symbol"
      assert order.target == 120.5
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Finance.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      assert {:ok, order} = Finance.update_order(order, @update_attrs)
      assert %Order{} = order
      assert order.action == "some updated action"
      assert order.status == "pending"
      assert order.quantity == 43
      assert order.stoploss == 456.7
      assert order.symbol == "some updated symbol"
      assert order.target == 456.7
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.update_order(order, @invalid_attrs)
      assert order == Finance.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Finance.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Finance.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Finance.change_order(order)
    end
  end

  describe "holdings" do
    alias Investing.Finance.Holding

    @valid_attrs %{bought_at: 120.5, quantity: 42, symbol: "some symbol"}
    @update_attrs %{bought_at: 456.7, quantity: 43, symbol: "some updated symbol"}
    @invalid_attrs %{bought_at: nil, quantity: nil, symbol: nil}

    def holding_fixture(attrs \\ %{}) do
      {:ok, holding} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Finance.create_holding()

      holding
    end

    test "list_holdings/0 returns all holdings" do
      holding = holding_fixture()
      assert Finance.list_holdings() == [holding]
    end

    test "get_holding!/1 returns the holding with given id" do
      holding = holding_fixture()
      assert Finance.get_holding!(holding.id) == holding
    end

    test "create_holding/1 with valid data creates a holding" do
      assert {:ok, %Holding{} = holding} = Finance.create_holding(@valid_attrs)
      assert holding.bought_at == 120.5
      assert holding.quantity == 42
      assert holding.symbol == "some symbol"
    end

    test "create_holding/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Finance.create_holding(@invalid_attrs)
    end

    test "update_holding/2 with valid data updates the holding" do
      holding = holding_fixture()
      assert {:ok, holding} = Finance.update_holding(holding, @update_attrs)
      assert %Holding{} = holding
      assert holding.bought_at == 456.7
      assert holding.quantity == 43
      assert holding.symbol == "some updated symbol"
    end

    test "update_holding/2 with invalid data returns error changeset" do
      holding = holding_fixture()
      assert {:error, %Ecto.Changeset{}} = Finance.update_holding(holding, @invalid_attrs)
      assert holding == Finance.get_holding!(holding.id)
    end

    test "delete_holding/1 deletes the holding" do
      holding = holding_fixture()
      assert {:ok, %Holding{}} = Finance.delete_holding(holding)
      assert_raise Ecto.NoResultsError, fn -> Finance.get_holding!(holding.id) end
    end

    test "change_holding/1 returns a holding changeset" do
      holding = holding_fixture()
      assert %Ecto.Changeset{} = Finance.change_holding(holding)
    end
  end
end
