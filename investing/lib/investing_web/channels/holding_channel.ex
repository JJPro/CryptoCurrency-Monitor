defmodule InvestingWeb.HoldingChannel do
  @moduledoc """
  The Holding Channel manages communication surrounding portfolio positions.

  Deprecated:
  (now balance and holdings are pushed inside action_panel,
  because other modules requires those data to be present
  as well, and action panel is perfect place to get those
  data since it is always present)
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
  require Logger

  def join("holdings:"<>uid, payload, socket) do
    if authorized?(payload) do
      socket = assign(socket, :uid, String.to_integer(uid))  # attach uid with socket

      # subscribe to financial servers
      # this is taken care of inside :send_inital_data message handler

      # Deprecated - see module doc for detail
        # # push holding positions immediately after joining
        # send(self, :send_initial_data)

      send(self(), :request_live_updates)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Deprecated - see module doc
    # @doc """
    # On joining the channel, the client should get those initial static data for his account:
    #   - account balance
    #   - list of all the holding assets (without gain/loss data)
    #
    # In addition, this function is also the best opportunity to subscribe to financial live updating services.
    # """
    # def handle_info(:send_initial_data, socket) do
    #   user = Accounts.get_user!(socket.assigns.uid) |> Investing.Repo.preload([:holdings])
    #   balance = user.balance
    #   holdings = user.holdings
    #
    #   # subscribe to financial services to get live updates
    #   Enum.each(holdings, &(Finance.subscribe(&1.symbol, self())))
    #
    #   push(socket, "initial data", %{
    #     balance: balance,
    #     holdings: holdings
    #   })
    #
    #   {:noreply, socket}
    # end

  def handle_info(:request_live_updates, socket) do
    user = Accounts.get_user!(socket.assigns.uid) |> Investing.Repo.preload([:holdings])

    Enum.each(user.holdings, &(Finance.subscribe(&1.symbol, self())))

    {:noreply, socket}
  end

  ##
  # Subscribe to financial servers and on :price_updated,
  #   simply push new price to the client, and let the client do the calculations
  #   about earnings and stuff, since only the client has complete information about the holdings.
  ##
  def handle_info({:price_updated, data}, socket) do
    push(socket, "price updated", data)
    {:noreply, socket}
  end

  def handle_info({:test, data}, socket) do
    Logger.info("received data: #{inspect data}")
    {:noreply, socket}
  end

  ##
  # Handle :subscribe_symbol message from the order_manager (this was triggered when new holding is created)
  #   - subscribe new holding to financial servers
  #
  # It's okay to send duplicate subscriptions, since quote servers state are unique mapset.
  ##
  def handle_info({:subscribe_symbol, symbol}, socket) do
    Finance.subscribe(symbol, self())
    {:noreply, socket}
  end

  def handle_info({:unsubscribe_symbol, symbol}, socket) do
    Finance.unsubscribe(symbol, self())

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
