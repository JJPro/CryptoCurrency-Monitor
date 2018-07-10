defmodule Investing.Finance.OrderManager do
  @moduledoc """
  Role:
  1. Creates order (to database and server state)
  2. Monitors orders and places them when target price is reached.
  """
  use GenServer
  alias Investing.Finance

### Public Interface: ###
  @doc """
  Creates order entry:
  1. Database entry
  2. Server state entry
  """
  def create_order(order) do

  end

### GenServer Implementations ###
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  load pending orders from DB to server state upon server startup.
  data structure of server state: %{symbol: [orders_objects], ...}
  :: {:ok, new_state}
  """
  def init(_state) do

  end

  def terminate(reason, state) do
    {:shutdown, state}
  end

  @doc """
  Asset servers will trigger this callback when price is updated.
  Refer to https://github.com/JJPro/CryptoCurrency-Monitor/issues/3 for working logic

  UPDATE:
  this function would be moved to threshold manager,
  then order manager and alert manager only need to deal with the real work when thresholds are met. 
  """
  def handle_info({:price_updated, %{symbol: symbol, price: price}}, state) do

  end
end
