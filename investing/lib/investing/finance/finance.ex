defmodule Investing.Finance do
  @moduledoc """
  The Finance context.
  """

  import Ecto.Query, warn: false
  alias Investing.Repo

  alias Investing.Finance.Asset

  @doc """
  Returns the list of assets.

  ## Examples

      iex> list_assets()
      [%Asset{}, ...]

  """
  def list_assets do
    Repo.all(Asset)
  end

  def list_assets_of_user(uid) do
    Repo.all( from a in Asset,
              where: a.user_id == ^uid,
              select: a)
  end

  @doc """
  Gets a single asset.

  Raises `Ecto.NoResultsError` if the Asset does not exist.

  ## Examples

      iex> get_asset!(123)
      %Asset{}

      iex> get_asset!(456)
      ** (Ecto.NoResultsError)

  """
  def get_asset!(id), do: Repo.get!(Asset, id)

  @doc """
  Creates a asset.

  ## Examples

      iex> create_asset(%{field: value})
      {:ok, %Asset{}}

      iex> create_asset(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_asset(attrs \\ %{}) do
    %Asset{}
    |> Asset.changeset(attrs)
    |> Repo.insert()
  end

  def lookup_asset(term) do
    # fetch data from gdax and alpha vantage
    lookup_crypto(term) ++ lookup_stock(term)
    |> IO.inspect(label: ">>>>> stock")
  end

  defp lookup_stock(term) do
    %{body: body, status_code: status_code} = HTTPoison.get!("https://ws-api.iextrading.com/1.0/stock/#{term}/company" |> IO.inspect(label: ">>>> stock query url"))

    case status_code do
      200 ->
        %{"companyName" => name, "symbol" => symbol, "exchange" => market} = Poison.decode!(body)
        [%{symbol: symbol, name: name, market: market}] |> IO.inspect(label: ">>>> stock lookup res")
      _ -> []
    end
  end

  defp lookup_crypto(term) do
    all_crypto_assets
    |> Enum.filter(
    fn crypto ->
      String.contains?(String.downcase(crypto.symbol), term) ||
      String.contains?(String.downcase(crypto.name), term) ||
      String.contains?(String.downcase(crypto.market), term)
    end)
    |> IO.inspect(label: ">>>>>>> crypto lookup res")
  end

  defp all_crypto_assets do
    [
      %{symbol: "BTC-USD", name: "Bitcoin USD", market: "CryptoCurrency"},
      %{symbol: "LTC-USD", name: "Litecoin USD", market: "CryptoCurrency"},
      %{symbol: "ETH-USD", name: "Ether USD", market: "CryptoCurrency"},
      %{symbol: "BCH-USD", name: "Bitcoin Cash USD", market: "CryptoCurrency"},
    ]
  end

  @doc """
  Updates a asset.

  ## Examples

      iex> update_asset(asset, %{field: new_value})
      {:ok, %Asset{}}

      iex> update_asset(asset, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_asset(%Asset{} = asset, attrs) do
    asset
    |> Asset.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Asset.

  ## Examples

      iex> delete_asset(asset)
      {:ok, %Asset{}}

      iex> delete_asset(asset)
      {:error, %Ecto.Changeset{}}

  """
  def delete_asset(%Asset{} = asset) do
    Repo.delete(asset)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking asset changes.

  ## Examples

      iex> change_asset(asset)
      %Ecto.Changeset{source: %Asset{}}

  """
  def change_asset(%Asset{} = asset) do
    Asset.changeset(asset, %{})
  end
end
