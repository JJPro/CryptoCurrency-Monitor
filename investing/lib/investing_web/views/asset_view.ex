defmodule InvestingWeb.AssetView do
  use InvestingWeb, :view
  alias InvestingWeb.AssetView

  def render("index.json", %{assets: assets}) do
    %{data: render_many(assets, AssetView, "asset.json")}
  end

  def render("show.json", %{asset: asset}) do
    %{data: render_one(asset, AssetView, "asset.json")}
  end

  def render("asset.json", %{asset: asset}) do
    %{id: asset.id,
      symbol: asset.symbol,
      market: asset.market}
  end
end
