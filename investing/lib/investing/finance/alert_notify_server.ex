defmodule Investing.Finance.AlertNotifyServer do
  @moduledoc """
  Checks real time price changes, and email notify the users if their alert limits are met
  """
  use GenServer
  alias Investing.Finance
  alias Investing.Finance.{CoinbaseServer, StockServer}

# Public Interface:
  def start_link do
    # {:ok, pid} = GenServer.start_link(__MODULE__, [], name: __MODULE__)
    # Process.monitor(pid)
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
    IO.puts ">>>>> AlertNotifyServer Started"
  end

  # Please call this function when ative alerts are added or removed.
  def reload_alerts do
    GenServer.cast(__MODULE__, :reload_alerts)
  end


# GenServer Implementation
  def init(_state) do
    # fetch all active alerts
    active_alerts = Finance.list_active_alerts_with_users()
    # filter out unique symbols
    symbols = active_alerts
    |> Enum.reduce(MapSet.new, fn (alert, acc) -> MapSet.put(acc, alert.symbol) end)
    |> MapSet.to_list
    # subscribe to their live updates
    batch_subscribe(symbols)
    # symbols |> Enum.each(fn s -> subscribe(s) end) # use this if batch_subscribe doesnt work

    # save active alerts (associated with their owner objects) as Server State
    {:ok, active_alerts}
  end

  def terminate(reason, state) do
    IO.puts ">>>>> Terminating, reason: #{inspect reason}, state: #{inspect state}"
    {:shutdown, state}
  end

  @doc """
  handle live updates:
  check if active alerts' conditions are met
  send emails if met, and mark alert as expired.
  """
  def handle_info({:update_asset_price, %{symbol: symbol, price: price}}, state) do
    # send email if limits are met.
    state
    |> Enum.each(fn alert ->
      if alert.symbol == symbol && Code.eval_string("#{price} #{alert.condition}") == true do
        # send email
        Investing.Email.basic_email(alert.user.email, symbol, alert.condition, price)
        # mark alert as expired
        Finance.update_alert(alert, %{expired: true})
      end
    end)
  end

  @doc """
  Testing: catch all
  """
  def handle_info(msg, state) do
    IO.inspect(msg, label: ">>>>>>>> received alerts update, msg is ")
    IO.inspect(state, label: ">>>>>>>> received alerts update, check for coditions")


  end

  def handle_cast(:reload_alerts, state) do
    # reload db records
    new_active_alerts = Finance.list_active_alerts_with_users()
    # filter out unique symbols
    new_symbols = new_active_alerts
    |> Enum.reduce(MapSet.new, fn (alert, acc) -> MapSet.put(acc, alert.symbol) end)
    |> MapSet.to_list

    old_symbols = state
    |> Enum.reduce(MapSet.new, fn (alert, acc) -> MapSet.put(acc, alert.symbol) end)
    |> MapSet.to_list

    subs = new_symbols -- old_symbols
    unsubs = old_symbols -- new_symbols
    batch_subscribe(subs)
    unsubs |> Enum.each(fn s -> unsubscribe(s) end)

    {:noreply, new_active_alerts}
  end

# Private Functions
  defp batch_subscribe(symbols) do
    cryptos = Enum.filter(symbols, fn s -> Finance.market(s) == "CryptoCurrency" end)
    stocks = symbols -- cryptos

    if length(cryptos) > 0, do: CoinbaseServer.batch_subscribe(cryptos, self())
    if length(stocks) > 0, do: StockServer.batch_subscribe(stocks, self())
  end

  defp subscribe(symbol) do
    case Finance.market(symbol) do
      "CryptoCurrency" ->
        CoinbaseServer.subscribe(symbol, self())
      _ ->
        StockServer.subscribe(symbol, self())
    end
  end

  defp unsubscribe(symbol) do
    case Finance.market(symbol) do
      "CryptoCurrency" ->
        CoinbaseServer.unsubscribe(symbol, self())
      _ ->
        StockServer.unsubscribe(symbol, self())
    end
  end

end
