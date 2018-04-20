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
end
