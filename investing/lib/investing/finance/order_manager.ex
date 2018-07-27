defmodule Investing.Finance.OrderManager do
  @moduledoc """
  Order Service management

  This module is part of the paper trading system.
  (Ref: Issue #3: https://github.com/JJPro/paper-trading-system/issues/3)

  Role:
  1. Monitors pending orders and places them when target price is reached.
  2. May split a realized order into another pending order if this is a limit order.
     Currently the system only supports _buy limit order_.

  (Ref: [What is a limit order?](https://en.wikipedia.org/wiki/Order_(exchange)#Limit_order))
  """
  use GenServer
  alias Investing.Finance
  alias Investing.Finance.{ThresholdManager, Order, Holding}
  alias Investing.Utils.Actions
  alias Investing.Accounts
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
  This function will be called when an order is placed.
  Do the following:
  1. remove order from server state
  2. expire the order entry, by updating the expired value to true in db
  3. check if order was an stoploss order
      if yes, place sell order for the stop loss (3.1. add to both db, and
                                                  3.2. server state, and
                                                  3.3 subscribe to threshold service)
  4. update user balance
  5. create holding record for the order

  """
  def handle_cast({:threshold_met, %{symbol: symbol, price: price, condition: condition}}, state) do

    new_state =
      state
      |> Map.update!(symbol, fn orders ->
        
      end)

    {_, new_state} = Map.get_and_update(state, symbol, fn orders ->
      if is_nil(orders) do # something went wrong if this happens
        Logger.error("in #{__MODULE__}, something went wrong handling message :threshold_met")
      else
        new_orders = Enum.reject(orders, fn order ->
          if condition(order) == condition do
            # mark order db entry as expired
            Finance.update_order(order, %{expired: true}) # Step 2.
            Actions.do_action :order_expired, order: order, price: price, condition: condition

            ### Step 4. update user balance
            update_account_balance(order, price)

            ### Step 5. create holding record for the placed order
            case order.action do
              "buy" ->
                {:ok, %Holding{} = holding} = Finance.create_holding(%{symbol: symbol, bought_at: price, quantity: order.quantity, user_id: order.user_id})
                Actions.do_action :holding_created, hoding: holding
              "sell" ->
                # TODO:
                # update the holding position for partial sell
                # or delete the holding record for total sell
                #
                # Do the following:
                # a. get current holding position
                # b. check residual quantity
                # c. reduce quantity and check if residual quantity is 0
                # d. update holding quantity or delete the record all together depends on the residual quantity in step c.
                # e. trigger off an action
                {:ok, %Holding{} = holding} = Finance.delete_holding(holding)
            end

            # deal with buy limit order split
            # TODO check what the stoploss value is when not provided on creation, is it NULL or 0?
            #       and revision of this block might be necessary accordingly
            unless (is_nil(order.stoploss) or order.stoploss == 0) do # this was an limit order
              {:ok, %Order{} = derived_order} = Finance.create_order(%Order{order | action: "sell", target: order.stoploss, stoploss: nil}) # Step 3.1
              add_order(derived_order) # Step 3.2
              ThresholdManager.subscribe(symbol, condition(derived_order), self(), true) # Step 3.3
              Actions.do_action :order_created, order: derived_order
            end

            true # Step 1.
          else
            false
          end
        end )
        {nil, new_orders} # Step 1.
      end
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
  end
end
