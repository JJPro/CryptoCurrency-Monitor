defmodule InvestingWeb.HoldingChannel do
  @moduledoc """
  The Holding Channel manages communication surrounding portfolio positions.

  On joining the channel, the client should get those initial static data for his account:
  - account balance
  - list of all the holding assets (without gain/loss data)

  On :balance_udpated, update balance and total equity values:
  Nothing to do here.
  This event is broadcasted by order_manager
  The client needs to handle this message to update the balance and total equity values.

  Subscribe to financial servers and on :price_updated,
    simply push new price to the client, and let the client do the calculations
    about earnings and stuff, since only the client has complete information about the holdings.

  Handle "subscribe symbol" message from the client side (this was triggered by a broadcast from order manager when new holding is created)
    - subscribe new holding to financial servers

  Handle "unsubscribe symbol" message from the client
  (this will be triggered when all holdings on a symbol is deleted/gone)
  """
  use InvestingWeb, :channel
  alias Investing.Finance
  alias Investing.Accounts

  def join("holding:"<>uid, payload, socket) do
    if authorized?(payload) do
      socket = assign(socket, :uid, String.to_integer(uid))  # attach uid with socket

      # subscribe to financial servers
      # this is taken care of inside :send_inital_data message handler

      # push holding positions immediately after joining
      send(self, :send_initial_data)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  On joining the channel, the client should get those initial static data for his account:
    - account balance
    - list of all the holding assets (without gain/loss data)

  In addition, this function is also the best opportunity to subscribe to financial live updating services.
  """
  def handle_info(:send_initial_data, socket) do
    user = Accounts.get_user!(socket.assigns.uid) |> Investing.Repo.preload([:holdings])
    balance = user.balance
    holdings = user.holdings

    # subscribe to financial services to get live updates
    Enum.each(holdings, &(Finance.subscribe(&1.symbol, self())))

    push(socket, "initial data", %{
      balance: balance,
      holdings: holdings
    })

    {:noreply, socket}
  end

  @doc """
  Subscribe to financial servers and on :price_updated,
    simply push new price to the client, and let the client do the calculations
    about earnings and stuff, since only the client has complete information about the holdings.
  """
  def handle_info({:price_updated, data}, socket) do
    push(socket, "price updated", data)
    {:noreply, socket}
  end

  @doc """
  Handle "subscribe symbol" message from the client side (this was triggered by a broadcast from order manager when new holding is created)
    - subscribe new holding to financial servers
  """
  def handle_in("subscribe symbol", %{"symbol" => symbol}, socket) do
    Finance.subscribe(symbol, self())

    {:noreply, socket}
  end
  def handle_in("unsubscribe symbol", %{"symbol" => symbol}, socket) do
    Finance.unsubscribe(symbol, self())

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
