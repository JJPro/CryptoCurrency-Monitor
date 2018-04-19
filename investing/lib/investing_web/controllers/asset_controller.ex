defmodule InvestingWeb.AssetController do
  use InvestingWeb, :controller

  alias Investing.Finance
  alias Investing.Finance.Asset

  action_fallback InvestingWeb.FallbackController

  def index(conn, _params) do
    assets = Finance.list_assets()
    render(conn, "index.json", assets: assets)
  end

  def create(conn, %{"asset" => asset_params}) do
    with {:ok, %Asset{} = asset} <- Finance.create_asset(asset_params |> IO.inspect(label: ">>>>> create asset: asset_params")) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", asset_path(conn, :show, asset))
      |> render("show.json", asset: asset)
    end
  end

  def show(conn, %{"id" => id}) do
    asset = Finance.get_asset!(id)
    render(conn, "show.json", asset: asset)
  end

  def update(conn, %{"id" => id, "asset" => asset_params}) do
    asset = Finance.get_asset!(id)

    with {:ok, %Asset{} = asset} <- Finance.update_asset(asset, asset_params) do
      render(conn, "show.json", asset: asset)
    end
  end

  def delete(conn, %{"id" => id}) do
    asset = Finance.get_asset!(id)
    with {:ok, %Asset{}} <- Finance.delete_asset(asset) do
      send_resp(conn, :no_content, "")
    end
  end
end
