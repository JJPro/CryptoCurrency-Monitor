defmodule InvestingWeb.AssetView do
  use InvestingWeb, :view
  alias InvestingWeb.AssetView

  def render("index.json", %{assets: assets}) do
    %{data: render_many(assets, AssetView, "asset.json")}
  end
  def render("index.json", %{prompts: prompts}) do
    %{data: render_many(prompts, AssetView, "prompt.json")}
  end

  def render("show.json", %{asset: asset}) do
    %{data: render_one(asset, AssetView, "asset.json")}
  end

  @doc """
  for rendering asset json
  """
  def render("asset.json", %{asset: asset}) do
    %{id: asset.id,
      symbol: asset.symbol}
  end

  @doc """
  for rendering prompt
  """
  def render("prompt.json", %{asset: asset}) do
    %{symbol: asset.symbol,
      name: asset.name,
      market: asset.market}
  end

end
