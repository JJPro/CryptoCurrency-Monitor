defmodule InvestingWeb.AssetController do
  use InvestingWeb, :controller

  alias Investing.Finance
  alias Investing.Finance.Asset
  # alias Investing.Accounts

  action_fallback InvestingWeb.FallbackController

  def index(conn, %{"token" => token}) do
    # list assets of user
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400) do
      assets = Finance.list_assets_of_user(user_id)
      render(conn, "index.json", assets: assets)
    end
  end

  def create(conn, %{"symbol" => symbol, "token" => token}) do
    with {:ok, user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400),
         {:ok, %Asset{} = asset} <- Finance.create_asset(%{symbol: symbol, user_id: user_id}) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", asset_path(conn, :show, asset))
      |> render("show.json", asset: asset)
    end
  end

  def lookup(conn, %{"term" => term}) do
    prompts = Finance.lookup_asset(term)

    render conn, "index.json", prompts: prompts# |> IO.inspect(label: ">>>> lookup result")
  end

  def show(conn, %{"id" => id}) do
    asset = Finance.get_asset!(id)
    render(conn, "show.json", asset: asset)
  end

  def delete(conn, %{"id" => id, "token" => token}) do
    asset = Finance.get_asset!(id)
    with {:ok, _user_id} <- Phoenix.Token.verify(conn, "auth token", token, max_age: 86400),
         {:ok, %Asset{}} <- Finance.delete_asset(asset) do
      send_resp(conn, :no_content, "")
    end
  end
end
