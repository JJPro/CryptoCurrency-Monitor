defmodule Investing.Finance.OrderManager do
  @moduledoc """
  Order Service management

  This module is part of the paper trading system.
  (Ref: Issue #3: https://github.com/JJPro/paper-trading-system/issues/3)

  Role:
  1. Monitors pending orders and executes them when target price is reached.
  2. May split a realized order into another pending order if this is a limit order.
     Currently the system only supports _buy limit order_.

  (Ref: [What is a limit order?](https://en.wikipedia.org/wiki/Order_(exchange)#Limit_order))
  """
  use GenServer
  alias Investing.Finance
  alias Investing.Finance.{ThresholdManager, Order, Holding}
  alias Investing.Utils.Actions
  require Logger


### Public Interface: ###
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  pass a new order to the service to monitor

  Note: OrderManager service is not responsible for creating order entries in the database,
        the database entry creation is already taken care of by OrderController.

  ## Parameters

    - order: Order object
  """
  def add_order(order) do
    GenServer.cast(__MODULE__, {:add_order, order})
  end

  @doc """
  delete an order from the system

  ## Parameters
    - order: Order object to delete
  """
  @spec del_order(Order) :: nil
  def del_order(order) do
    GenServer.cast(__MODULE__, {:del_order, order})
  end

  @doc """
  Places new order.

  ## NOTE
  This creates db entry, only call this when server is live, and let this function handle db and server operations
    - creates db entry
    - requests to monitor order
  """
  @spec place_order(Order) :: nil
  def place_order(order = %Order{action: "sell"}) do
    order
    |> Finance.create_order() # create db entry
    |> add_order              # add to order manager daemon to monitor

    Actions.do_action :order_placed, order: order
  end

### GenServer Implementations ###
  @doc """
  Triggerred during module startup.
  1. setup server state, loads pending orders from database.
  2. subscribe to threshold_manager daemon

  ## Return
    - {:ok, %{"symbol1" => [order list], "symbol2" => [order list], ...}}
  """
  @spec init(List.t()) :: {:ok, map()}
  def init(_state) do
    active_orders = Finance.list_active_orders()

    # subscribe to threshold manager daemon
    initial_state = Enum.reduce(active_orders, %{},
    fn (order, acc) ->
      ThresholdManager.subscribe(order.symbol, condition(order), self(), true) # step 2.

      {_, new_acc} = Map.get_and_update(acc, order.symbol, fn orders ->
        if is_nil(orders), do: {nil, [order]}, else: {nil, [order|orders]}
      end)
      new_acc
    end) # Step 1.

    {:ok, initial_state}
  end

  def terminate(_reason, state) do
    {:shutdown, state}
  end

  @doc """
  handling :threshold_met message from ThresholdManager daemon
  This function will be called to execute the order.

  Description:
    find all satisfied orders, execute them and remove them from server state.
  """
  def handle_cast({:threshold_met, %{symbol: symbol, price: price, condition: condition}}, state) do

    new_state =
      state
      |> Map.update!(symbol, fn orders ->

        Enum.reject(orders, fn order ->
          cond do
            condition(order) == condition -> # order is matched
              execute_order(order, price)
              true

            true -> false
          end
        end)

      end)
    {:noreply, new_state}
  end

  @doc """
  Adds a new order to system while the system is already running.

  ## Parameters
    - order: Order object
    - state: current state of this server.
             state is of data format:
             %{"symbol" => [list of pending orders]}
  """
  def handle_cast({:add_order, order}, state) do
    ThresholdManager.subscribe(order.symbol, condition(order), self(), true)

    {_, new_state} = Map.get_and_update(state, order.symbol, fn orders ->
      if is_nil(orders), do: {nil, [order]}, else: {nil, [order|orders]}
    end)

    {:noreply, new_state}
  end

  @doc """
  delete an order from the system.
  This is triggerred when user manually deletes an active order,
  needs to do the following:
  1. remove this order from server state;
  2. unsubscribe from threshold service if there is no orders of the same condition and symbol

  ## Parameters
    - order: Order object to delete
    - state: current state of this server.
             state is of data format:
             %{"symbol" => [list of pending orders]}
  """
  def handle_cast({:del_order, order}, state) do
    {_, new_state} = Map.get_and_update(state, order.symbol, fn orders ->
      if is_nil(orders) do # WARNING: this shouldn't happen, state is outta sync if this happens
        IO.warn("in #{__MODULE__}, order state is out of sync")
        {nil, []}
      else
        new_orders = Enum.reject(orders, &(&1.id == order.id) ) # Step 1.
        if not Enum.any?(new_orders, &(condition(&1) == condition(order))) do
          ThresholdManager.unsubscribe(order.symbol, condition(order), self()) # Step 2.
        end
        {nil, new_orders} # Step 1.
      end
    end) # Step 1

    {:noreply, new_state}
  end

  @doc """
  Places a buy-stoploss order.

  Do the following:
  1. expire the order entry, by setting expired to true in db
  2. place sell order for the stop loss
  3. update user balance
  4. create holding record for the order
  """
  @spec execute_order(Order.t(), float) :: nil

  # when this is a buy-stoploss order
  defp execute_order(
    order = %Order{stoploss: stoploss, action: action},
    price)
  # TODO check what the stoploss value is when not provided on creation, is it NULL or 0?
  #       and revision of this block might be necessary accordingly
  when action == "buy" and not (is_nil(stoploss) or stoploss == 0)
  do

    order
    |> expire_order() # 1.
    |> update_account_balance(price) # 3.
    |> update_holding_position(price) # 4.

    # 2. place a sell order for the stoploss part
    _sell_order =
    %Order{ order | action: "sell", target: order.stoploss, stoploss: nil}
    |> place_order()
  end

  # this is a normal order (sell or buy)
  defp execute_order(order = %Order{}, price) do
    order
    |> expire_order()
    |> update_account_balance(price)
    |> update_holding_position(price)

    Actions.do_action :order_executed, order: order, at_price: price, condition: condition(order)
  end

  # Description:
  # two cases depends on order type:
  #   buy order -> create holding record
  #   sell order -> delete holding record
  # then notify whoever care about this change via actions
  @spec update_holding_position(Order, float) :: Order
  defp update_holding_position(order = %Order{action: "buy"}, trading_price) do

    # create holding record
    {:ok, %Holding{} = holding} = Finance.create_holding(
      %{
        symbol: order.symbol,
        bought_at: trading_price,
        quantity: order.quantity,
        user_id: order.user_id
      })

    # trigger action
    Actions.do_action :holding_updated, action: :increase, hoding: holding

    order
  end
  defp update_holding_position(order = %Order{action: "sell"}, _trading_price) do

    # Do the following:
    #   collect all holdings about this symbol, sorted by creation time
    #   decrease or delete holdings in chronical order
    holdings =
      Finance.list_user_holdings_for_symbol_sorted_by_creation_time(order.user_id, order.symbol)
      |> IO.inspect(label: ">>>>> all holdings for symbol #{order.symbol}")

    holding_quantity_to_decrease = order.quantity

    _decrease_holdings(holdings, holding_quantity_to_decrease)

    order
  end

  defp _decrease_holdings(_, 0), do: nil
  defp _decrease_holdings([], qty_to_decrease) when qty_to_decrease > 0, do: Logger.error("decrease on empty holdings")
  defp _decrease_holdings([], _), do: nil
  defp _decrease_holdings([holding = %Holding{quantity: qty}|rest], qty_to_decrease) when qty_to_decrease >= qty do
    # remove holding record
    Finance.delete_holding(holding)
    Actions.do_action :holding_updated, action: :delete, holding: holding

    qty_to_decrease = qty_to_decrease - qty
    _decrease_holdings(rest, qty_to_decrease)
  end
  # qty_to_decrease < holding.quantity
  defp _decrease_holdings([holding = %Holding{quantity: qty}|_], qty_to_decrease) do
    # decrease holding record
    updated_holding_qty = qty - qty_to_decrease
    Finance.update_holding(holding, %{quantity: updated_holding_qty})
    Actions.do_action :holding_updated, action: :decrease, holding: holding
  end


  @spec expire_order(Order.t()) :: nil
  defp expire_order(order = %Order{}) do
    Finance.update_order(order, %{expired: true})
  end



  @doc """
  calculate the appropriate condition string for a given order.
  """
  @spec condition(Order) :: String.t()
  defp condition(order) do
    case order.action do
      "buy" -> "<= #{order.target}"
      "sell" -> ">= #{order.target}"
    end
  end

  defp update_account_balance(order, price) do
    # update user account balance with processed order and trading price.
    action = case order.action do
      "buy" -> :subtract
      "sell" -> :add
    end
    Finance.update_user_balance(order.user_id, action, price * order.quantity)
    Actions.do_action :balance_updated, uid: order.user_id

    order
  end

end
