defmodule InvestingWeb.OrderChannel do
  @moduledoc """
  # This channel is responsible for:
  ## Pushing to the front
    - push list of orders to the front after join
    - push order to the front after creation, this is taken care of by ordermanager.
    - push updates to status of orders when an order is executed or canceled.
      This is taken care of by order manager.

  ## Receiving from the front:
    - to cancel a pending order.

  # Things to consider:
    - how many orders you want to keep in the database:
      Keep all, until we reach the point to make a decision later.

  ## Implementation Details
    - socket.assigns:
      - uid

  ## More About Orders
  1. Orders cannot be deleted, however, you can cancel an pending order.
     All orders are saved forever on the server.

  2. Placing order is not dealt with from client side of this channel, because
     placing order is done through the bottom action panel, and handled by its channel
  """
  use InvestingWeb, :channel
  alias Investing.Finance
  alias Investing.Utils.Actions
  alias Investing.Finance.OrderManager

  def join("order:"<>uid, payload, socket) do
    if authorized?(payload) do
      socket = assign(socket, :uid, uid)       # attach uid with socket

      # push order history list immediately after joining
      send(self, :list_orders)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Handles canceling order request from the client.

  Simply call order_manager's function to do the job.
  It already includes broadcasting to the clients.
  """
  def handle_in("cancel order", %{"order_id" => order_id}, socket) do
    order_id
    |> Finance.get_order!()
    |> OrderManager.cancel_order()

    # Broadcasting to the clients is taken care of by OrderManager, nothing to do here.

    {:noreply, socket}
  end

  # # Channels can be used in a request/response fashion
  # # by sending replies to requests from the client
  # def handle_in("ping", payload, socket) do
  #   {:reply, {:ok, payload}, socket}
  # end

  # # It is also common to receive messages from the client and
  # # broadcast to everyone in the current topic (order:lobby).
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  @doc """
  Send all orders to the front
  This is triggered immedately after successfully joining the channel.

  ## Description:
  sends back two lists:
  1. active orders
  2. inactive orders, including executed ones and canceled ones

  List items in **reverse-chronological order** (keep the latest entries on top)
  """
  def handle_info(:list_orders, socket) do
    active_orders = list_active_orders(socket)
    inactive_orders = list_inactive_orders(socket)

    push(socket, "init order list", %{
      # WARNING
      # This may cause Poison Encoding issues,
      # sovle by using @derive attr inside the order schema
      # to specify which fields and how to json encode
      # the struct.
      active: active_orders,
      inactive: inactive_orders
    })

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp list_active_orders(socket), do: Finance.list_active_orders_of_user(socket.assigns.uid)
  defp list_inactive_orders(socket), do: Finance.list_inactive_orders_of_user(socket.assigns.uid)

end
