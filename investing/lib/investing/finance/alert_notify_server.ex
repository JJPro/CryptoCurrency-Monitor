defmodule Investing.Finance.AlertNotifyServer do
  @moduledoc """
  Checks real time price changes, and email notify the users if their alert limits are met
  """
  use GenServer
  alias Investing.Finance
  alias Investing.Finance.{CoinbaseServer, StockServer}

# Public Interface:
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Please call this function when ative alerts are added or removed.
  def reload_alerts do
    GenServer.cast(__MODULE__, :reload_alerts)
  end


# GenServer Implementation
  def init(_state) do
    # IO.puts ">>>>> Initializing AlertNotifyServer"
    # fetch all active alerts
    active_alerts = Finance.list_active_alerts_with_users()
    # filter out unique symbols
    symbols = active_alerts
    |> Enum.reduce(MapSet.new, fn (alert, acc) -> MapSet.put(acc, alert.symbol) end)
    |> MapSet.to_list
    # subscribe to their live updates
    Finance.batch_subscribe(symbols, self)
    # symbols |> Enum.each(fn s -> subscribe(s) end) # use this if batch_subscribe doesnt work

    # save active alerts (associated with their owner objects) as Server State
    {:ok, active_alerts}
  end

  def terminate(reason, state) do
    # IO.puts ">>>>> Terminating,"
    # IO.inspect(reason, label: "      reason")
    # IO.inspect(state, label: "      state")
    {:shutdown, state}
  end

  @doc """
  handle live updates:
  check if active alerts' conditions are met
  send emails if met, and mark alert as expired.
  """
  def handle_info({:update_asset_price, %{symbol: symbol, price: price}}, state) do
    # send email if limits are met.
    new_state = state
    |> Enum.filter(fn alert ->
      # IO.puts ">>>>> Checking Alert #{alert.symbol} #{symbol}, price: #{price}, condition: #{alert.condition}"
      if alert.symbol == symbol do
        with {satisfy?, _} <- Code.eval_string("#{price} #{alert.condition}") do

          if satisfy? do
            # IO.puts ">>>>> Alert triggered"
            # send email
            Investing.Email.basic_email(alert.user.email, symbol, alert.condition, price)
            # mark alert as expired
            Finance.update_alert(alert, %{expired: true})
            # remove alert from state, return false to filter it out
            false
          else
            true
          end
        end
      else
        true
      end
    end)

    {:noreply, new_state}
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
    Finance.batch_subscribe(subs, self)
    Finance.batch_unsubscribe(unsubs, self)

    {:noreply, new_active_alerts}
  end

end
