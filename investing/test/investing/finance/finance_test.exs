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
end
