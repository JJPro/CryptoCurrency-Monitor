defmodule Investing.Finance.AlertManager do
  @moduledoc """
  responsible for:
  1. CRUD operations
  2. Get quotes and email notify the users if their alert limits are met
  """
  use GenServer
  alias Investing.Finance
  alias Investing.Finance.Alert
  alias Investing.Finance.ThresholdManager
  alias Investing.Repo
  alias Investing.Utils.Actions
  require Logger

# Public Interface:
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Creates new alert.

  This creates db entry, only call this when server is live, and let this function
  handle db and server operations
    - creates db entry
    - requests to monitor alert
  """
  @spec create_alert(%Alert{}) :: nil
  def create_alert(alert) do
    {:ok, alert} = Finance.create_alert(alert) # db entry

    add_alert(alert)   # attach alert to this daemon to monitor and operate

    # broadcast this event
    # broadcast to alert_channel clients about alert creation
    InvestingWeb.Endpoint.broadcast!("alert:#{alert.user_id}", "alert created", %{alert: alert})
    # broadcast to alert_channel processes to subscribe to live quotes
    Phoenix.PubSub.broadcast!(Investing.PubSub, "alert:#{alert.user_id}", {:subscribe_symbol, alert.symbol})
  end

  @doc """
  Deletes an alert.

    - removes db entry
    - removes from daemon state
    - broadcast event
  """
  @spec delete_alert(%Alert{}) :: nil
  def delete_alert(alert) do
    Finance.delete_alert(alert) # removes db entry

    if !alert.expired do # do the following only when alert is alive 
      del_alert(alert)  # remove from daemon state, iff it is live

      if __last_active_alert_of_same_symbol_and_user?(alert) do
        Phoenix.PubSub.broadcast!(Investing.PubSub, "alert:#{alert.user_id}", {:unsubscribe_symbol, alert.symbol})
      end
    end

    # broadcast event
    InvestingWeb.Endpoint.broadcast!("alert:#{alert.user_id}", "alert deleted", %{alert: alert})
  end

  defp __last_active_alert_of_same_symbol_and_user?(alert) do
    alerts = Finance.list_active_alerts_of_user(alert.user_id)

    Enum.any?(alerts, &(&1.symbol == alert.symbol))
  end

  ##
  # add new alert to the system.
  #
  # ## Parameters
  #
  #   - alert: Alert object
  ##
  @spec add_alert(Alert.t()) :: nil
  defp add_alert(alert = %Alert{}) do
    GenServer.cast(__MODULE__, {:add_alert, alert})
  end

  ##
  # delete an alert from the system.
  #
  # ## Parameters
  #   - alert: Alert object to delete
  ##
  @spec del_alert(Alert.t()) :: nil
  defp del_alert(alert) do
    GenServer.cast(__MODULE__, {:del_alert, alert})
  end


### GenServer Implementation
  @doc """
  1. setup server state, loads active alerts from database.
  2. subscribe to threshold_manager service.

  ## Returns
    - {:ok, [list of active alerts]}
  """
  @spec init(List.t()) :: {:ok, List.t()}
  def init(_state) do
    # IO.puts ">>>>> Initializing AlertManager"
    # fetch all active alerts
    active_alerts = Finance.list_active_alerts_with_users()

    # subscribe to threshold manager
    Enum.each( active_alerts,
    fn alert ->
      ThresholdManager.subscribe(alert.symbol, alert.condition, self(), true)
    end)

    # save active alerts (associated with their owner objects) as Server State
    {:ok, active_alerts}
  end

  def terminate(_reason, state) do
    # IO.puts ">>>>> Terminating,"
    # IO.inspect(reason, label: "      reason")
    # IO.inspect(state, label: "      state")
    {:shutdown, state}
  end

  ##
  # handle :threshold_met message from threshold service
  # This function will be called when an alert threshold is satisfied.
  # Do the following:
  # 1. send email
  # 2. mark alert as expired.
  # 3. remove this alert from server state.
  ##
  def handle_cast({:threshold_met, %{symbol: symbol, price: price, condition: condition}}, state) do
    # send email for this alert
    # update server state, by rejecting this alert.
    new_state = state
    |> Enum.reject(
    fn alert ->

      if (alert.symbol == symbol && alert.condition == condition) do
        alert = alert |> Repo.preload([:user]) # get the user property
        # send email
        Investing.Email.basic_email(alert.user.email, symbol, condition, price)
        # mark alert as expired
        Finance.update_alert(alert, %{expired: true})

        InvestingWeb.Endpoint.broadcast!("alert:#{alert.user_id}", "alert expired", %{alert: alert})
        if __last_active_alert_of_same_symbol_and_user?(alert) do
          Phoenix.PubSub.broadcast!(Investing.PubSub, "alert:#{alert.user_id}", {:unsubscribe_symbol, alert.symbol})
        end
        Actions.do_action :alert_sent, alert: alert, price: price, condition: condition

        Logger.debug("marked alert as expire, and removing it from server state")
        true # remove alert from state, return true to reject it out
      else
        false # keep alert in server state, return false to keep it in.
      end
    end
    )

    # IO.inspect(new_state, label: ">>>>> verifying new state: ")

    {:noreply, new_state}
  end

  ##
  # add a new alert the system, needs to do the following:
  # 1. add to server state; ✅
  # 2. subscribe new alert to threshold service. ✅
  ##
  def handle_cast({:add_alert, alert}, state) do
    ThresholdManager.subscribe(alert.symbol, alert.condition, self(), true)

    {:noreply, [alert|state]} # add alert to server state
  end

  ##
  # delete an alert from the system, needs to do the following:
  # 1. remove this alert from server state; ✅
  # 2. unsubscribe from threshold service if there is no alerts of the same condition and symbol ✅
  ##
  def handle_cast({:del_alert, alert}, state) do
    new_state = Enum.reject(state, fn a -> a.id == alert.id end) #|> IO.inspect(label: ">>>>> new state after deletion")

    # step 2.
    if not Enum.any?(new_state, fn a -> a.symbol == alert.symbol && a.condition == alert.condition end) do
      ThresholdManager.unsubscribe(alert.symbol, alert.condition, self())
    end

    {:noreply, new_state} # step 1.
  end
end
