defmodule Investing.Finance.ThresholdManager do
  @moduledoc """
  Other modules can subscribe to ThresholdManager, which checks prices change in
  real time, and get notified, via :threshold_met message, when thresholds are met.

  ## Note:
  One important thing to notice is that there are no duplicate entries in the server state.

  server state format:
  %{
    symbol1: [%{condition: xx, pid: xx, transient?: bool}, ...],
    symbol2: [%{condition: xx, pid: xx, transient?: bool}, ...],
    ...
  }

  message format (subscribers need to handle this message):
  :threshold_met, %{symbol: xxx, condition: xxx, price: xxx}
  """
  use GenServer
  require Logger
  alias Investing.Finance

### Public Interface:
  def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  subscribers call this function to subscribe to the service.

  string symbol:    symbol to set the threshold for
  string condition: the threshold condition, e.g. "> 200"
  PID pid:          the subscriber pid, usually self\0
  bool transient?:   is the threshold transient? If transient, threshold is only valid for once, and will automatically delete itself when condition is met.
  """
  def subscribe(symbol, condition, pid, transient? \\ true) do
    GenServer.cast(__MODULE__, {:add_subscriber, {symbol, condition, pid, transient?}})
  end

  @doc """
  subscribers call this function to unsubscribe from the service.

  """
  def unsubscribe(symbol, condition, pid) do
    GenServer.cast(__MODULE__, {:del_subscriber, {symbol, condition, pid}})
  end


### GenServer Implementation
  def init(args) do
    {:ok, args}
  end
  def terminate(_reason, state) do
    {:shutdown, state}
  end

  ##
  # add subscriber to server state map, and subscribe to finance servers
  # There are no duplicates in server state, use MapSet as an intermediate to process the addition operation.
  #
  # string symbol:    symbol to set the threshold for
  # string condition: the threshold condition, e.g. "> 200"
  # PID pid:          the subscriber pid, usually self/0
  # bool transient?:   is the threshold transient? If transient, threshold is only valid for once, and will automatically delete itself when condition is met.
  ##
  def handle_cast({:add_subscriber, {symbol, condition, pid, transient?}}, state) do

    # subscribe to finance servers.
    Finance.subscribe(symbol, self())

    # new server state
    subscribers = Map.get(state, symbol, []) # get current subscribers, returns [] if doesn't exist
    new_subscribers = MapSet.new(subscribers)
    |> MapSet.put(%{condition: condition, pid: pid, transient?: transient?})
    |> MapSet.to_list # add new subscriber to list.

    {:noreply, Map.put(state, symbol, new_subscribers)}
  end

  ##
  # remove subscriber entry from the server state map,
  # and unsub from finance servers if there is no more entries for this symbol.
  #
  # There are no duplicates in the server state.
  #
  # ## Parameters
  #   - symbol: String      Symbol for this operation
  #   - condition: String   The threshold condition, e.g. "> 200"
  #   - pid: PID            The subscriber's pid, usually passing self/0
  #
  # ## Does the following:
  # 1. remove entry from server state
  # 2. unsubscribe from finance servers if new entry list for the symbol becomes empty
  ##
  def handle_cast({:del_subscriber, {symbol, condition, pid}}, state) do
    subscribers = Map.get(state, symbol, [])

    # step 1
    new_subscribers = Enum.reject(subscribers,
    fn th -> th.condition == condition && th.pid == pid end)

    # step 2
    if (length(new_subscribers) == 0) do
      Finance.unsubscribe(symbol, self())
    end

    {:noreply, %{state|symbol => new_subscribers}}
  end

  ##
  # This message is received from coinbase and stock servers when prices are updated, you must handle it.
  #
  # Check thresholds. Do the following if thresholds are met:
  # 1. Notify the pids for each satisfied threshold.
  # 2. Remove the subscriber from the list if threshold is trasient.
  # 3. unsubscribe from finance services if there is no more entries for the symbol
  ##
  def handle_info({:price_updated, %{symbol: symbol, price: price}}, state) do
    # Logger.info("threshold manager price updated, price is number? #{is_number(price)}")
    {_, new_state} = state |> Map.get_and_update(symbol, fn thresholds ->
      new_thresholds = thresholds |> Enum.reject(  # step 2.
      fn (%{condition: condition, pid: pid, transient?: transient?}) -> # compare price and evaluate condition, to filter out all satisfied thresholds.
        {satisfy?, _} = Code.eval_string("#{price} #{condition}")
        remove? = if satisfy? do

          # Step 1.
          GenServer.cast(pid, {:threshold_met, %{symbol: symbol, condition: condition, price: price}})
          # Step 2.
          transient?
        else
          false
        end
        # return false if threshold is both met and being transient.
        # otherwise return true.
        remove? # step 2.
      end)

      # IO.inspect(new_thresholds, label: "new thresholds after price update")

      # step 3.
      if length(new_thresholds) == 0 do
        IO.puts "Unsubing from symbol #{symbol}"
        Finance.unsubscribe(symbol, self())
      end

      {thresholds, new_thresholds}
    end)

    {:noreply, new_state}
  end

end
