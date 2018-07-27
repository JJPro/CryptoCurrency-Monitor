defmodule Investing.Finance do
  @moduledoc """
  The Finance context.
  """

  import Ecto.Query, warn: false
  alias Investing.Repo

  alias Investing.Finance.Asset
  alias Investing.Finance.{StockServer, CoinbaseServer}
  alias Investing.Accounts
  alias Investing.Accounts.User

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
  end

  defp lookup_stock(term) do
    %{body: body, status_code: status_code} = HTTPoison.get!("https://ws-api.iextrading.com/1.0/stock/#{term}/company")

    case status_code do
      200 ->
        %{"companyName" => name, "symbol" => symbol, "exchange" => market} = Poison.decode!(body)
        [%{symbol: symbol, name: name, market: market}]
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
  end

  defp all_crypto_assets do
    [
      %{symbol: "BTC-USD", name: "Bitcoin USD", market: "CryptoCurrency"},
      %{symbol: "LTC-USD", name: "Litecoin USD", market: "CryptoCurrency"},
      %{symbol: "ETH-USD", name: "Ether USD", market: "CryptoCurrency"},
      %{symbol: "BCH-USD", name: "Bitcoin Cash USD", market: "CryptoCurrency"},
    ]
  end

  def market(symbol) do
    if symbol in Enum.map(all_crypto_assets, fn c -> c.symbol end) do
      "CryptoCurrency"
    else
      # TODO: query database for market name
      "query database for market name"
    end
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

  alias Investing.Finance.Alert

  @doc """
  Returns the list of alerts.

  ## Examples

      iex> list_alerts()
      [%Alert{}, ...]

  """
  def list_alerts do
    Repo.all(Alert)
  end

  def list_alerts_of_user(uid) do
    Repo.all( from a in Alert,
              where: a.user_id == ^uid,
              select: a)
  end

  def list_active_alerts_with_users do
    Repo.all( from a in Alert,
              where: a.expired == false,
              select: a)
    |> Repo.preload([:user])
  end

  @doc """
  Gets a single alert.

  Raises `Ecto.NoResultsError` if the Alert does not exist.

  ## Examples

      iex> get_alert!(123)
      %Alert{}

      iex> get_alert!(456)
      ** (Ecto.NoResultsError)

  """
  def get_alert!(id), do: Repo.get!(Alert, id)

  @doc """
  Creates a alert.

  ## Examples

      iex> create_alert(%{field: value})
      {:ok, %Alert{}}

      iex> create_alert(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_alert(attrs \\ %{}) do
    %Alert{expired: false}
    |> Alert.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a alert.

  ## Examples

      iex> update_alert(alert, %{field: new_value})
      {:ok, %Alert{}}

      iex> update_alert(alert, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_alert(%Alert{} = alert, attrs) do
    alert
    |> Alert.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Alert.

  ## Examples

      iex> delete_alert(alert)
      {:ok, %Alert{}}

      iex> delete_alert(alert)
      {:error, %Ecto.Changeset{}}

  """
  def delete_alert(%Alert{} = alert) do
    Repo.delete(alert)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking alert changes.

  ## Examples

      iex> change_alert(alert)
      %Ecto.Changeset{source: %Alert{}}

  """
  def change_alert(%Alert{} = alert) do
    Alert.changeset(alert, %{})
  end

  def subscribe(symbol, channel) do
    case market(symbol) do
      "CryptoCurrency" ->
        CoinbaseServer.subscribe(symbol, channel)
      _ ->
        StockServer.subscribe(symbol, channel)
    end
  end

  def unsubscribe(symbol, channel) do
    case market(symbol) do
      "CryptoCurrency" ->
        CoinbaseServer.unsubscribe(symbol, channel)
      _ ->
        StockServer.unsubscribe(symbol, channel)
    end
  end

  def batch_subscribe(symbols, channel) do
    cryptos = Enum.filter(symbols, fn s -> market(s) == "CryptoCurrency" end)
    stocks = symbols -- cryptos

    if length(cryptos) > 0, do: CoinbaseServer.batch_subscribe(cryptos, channel)
    if length(stocks) > 0, do: StockServer.batch_subscribe(stocks, channel)
  end

  def batch_unsubscribe(symbols, channel) do
    cryptos = Enum.filter(symbols, fn s -> market(s) == "CryptoCurrency" end)
    stocks = symbols -- cryptos

    if length(cryptos) > 0, do: CoinbaseServer.batch_unsubscribe(cryptos, channel)
    if length(stocks) > 0, do: StockServer.batch_unsubscribe(stocks, channel)
  end

  def unsubscribe_all(channel) do
    CoinbaseServer.unsubscribe_all(channel)
    StockServer.unsubscribe_all(channel)
  end

  alias Investing.Finance.Order

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  def list_active_orders do
    Repo.all( from o in Order,
              where: o.expired == false,
              select: o)
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{source: %Order{}}

  """
  def change_order(%Order{} = order) do
    Order.changeset(order, %{})
  end

  alias Investing.Finance.Holding

  @doc """
  Returns the list of holdings.

  ## Examples

      iex> list_holdings()
      [%Holding{}, ...]

  """
  def list_holdings do
    Repo.all(Holding)
  end

  @doc """
  Gets a single holding.

  Raises `Ecto.NoResultsError` if the Holding does not exist.

  ## Examples

      iex> get_holding!(123)
      %Holding{}

      iex> get_holding!(456)
      ** (Ecto.NoResultsError)

  """
  def get_holding!(id), do: Repo.get!(Holding, id)

  def get_holding_ do

  end

  @doc """
  Creates a holding.

  ## Examples

      iex> create_holding(%{field: value})
      {:ok, %Holding{}}

      iex> create_holding(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_holding(attrs \\ %{}) do
    %Holding{}
    |> Holding.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a holding.

  ## Examples

      iex> update_holding(holding, %{field: new_value})
      {:ok, %Holding{}}

      iex> update_holding(holding, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_holding(%Holding{} = holding, attrs) do
    holding
    |> Holding.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Holding.

  ## Examples

      iex> delete_holding(holding)
      {:ok, %Holding{}}

      iex> delete_holding(holding)
      {:error, %Ecto.Changeset{}}

  """
  def delete_holding(%Holding{} = holding) do
    Repo.delete(holding)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking holding changes.

  ## Examples

      iex> change_holding(holding)
      %Ecto.Changeset{source: %Holding{}}

  """
  def change_holding(%Holding{} = holding) do
    Holding.changeset(holding, %{})
  end

  @doc """
  Updates user account balance.

  ## Parameters
    - user: user id or user object
    - action: :add or :subtract
    - amount: float  The amount of money to add or subtract
  """
  @spec update_user_balance(integer | %User{}, atom(), float()) :: boolean()
  def update_user_balance(%User{} = user, action, amount) do
    balance = case action do
      :add ->
        user.balance + amount
      :subtract ->
        user.balance - amount
    end  # get new balance value

    # update user with new balance
    from(u in User, update: [set: [balance: ^balance]], where: u.id == ^user.id)
    |> Repo.update_all([]) # lookup `h Repo.update_all for usage`

  end
  def update_user_balance(user_id, action, amount) when is_number(user_id) do
    user = Accounts.get_user!(user_id)
    update_user_balance(user, action, amount)
  end
end
