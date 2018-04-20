defmodule InvestingWeb.ActionPanelChannel do
  use InvestingWeb, :channel

  def join("action_panel:*", payload, socket) do
    IO.puts ">>>> joining action_panel"
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (action_panel:lobby).
  def handle_in("symbol select", payload, socket) do
    # TODO:
    # add symbol to server monitor list
    # in server: push "update_current_asset" down the websocket if there is change in price.

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
