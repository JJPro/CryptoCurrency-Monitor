defmodule Investing.Utils.Actions do
  @moduledoc """
  The Action API.
  Provides utility functions to operate on action hooks.

  ## Available Actions:
    - :order_expired, callback/1 format: (order: order, price: current_price, condition: condition_string) -> nil
      called after order is realized.

    - :order_created, callback/1: (order: order) -> nil
      called after stoploss order is realized and new sell order is generated.

    - :alert_sent, callback/1 format: (alert: alert, price: current_price, condition: condition_string) -> nil
      called after the alert message is sent.

    - :balance_updated, callback/1: (uid: user_id) -> nil

  ## About Actions:
  Actions are the hooks that the system launches at specified points during execution, or when specific events occur. Plugins can specify that one or more of
  its callback functions are executed at these points, using the Action API.

  For a read about actions: [WordPress Plugin - Actions](https://codex.wordpress.org/Plugin_API#Actions)


  ## How are actions stored:
  Actions are stored in an ETS bag type table, named :actions.
  Benefits of bag type table:
  1. Bag type table allows multiple callbacks to be hooked onto an action
  2. No duplication objects are allowed, so multiple additions of the same
      callback won't result in the callback being triggerred more than once.

  ## Caveats/Warning:
  Pay attention to the order of where you call add_action and apply_action
  add_action has to be called prior to apply_action.
  Although this is so obvious, yet worth pointing out.

  ## Extra Discoveries During Testing:
  - the action callback function can be private
  - you can call private functions inside the callback.
  """



  @doc """
  Hooks a callback function on to a specific action.

  ## Parameters
    - action  : Atom                The name of the action to hook onto
    - callback: function reference  The callback function to hook onto the action.
  """
  @spec add_action(atom(), (keyword() -> nil)) :: nil
  def add_action(action, callback) do
    # create the table if non-exists
    if :ets.info(:actions) == :undefined do
      :ets.new(:actions, [:bag, :named_table])
    end

    :ets.insert(:actions, {action, callback})
  end

  @doc """
  Triggers all callback functions hooked onto the action, with provided args.

  Implementation:
  Do the following:
  1. Get all the callback functions hooked onto this action
  2. Call those functions with provided arguments one by one.
  """
  @spec do_action(atom(), keyword()) :: nil
  def do_action(action, args \\ []) do
    cond do
      # immediately return if table is non-exist
      :ets.info(:actions) == :undefined -> nil
      # immediately return if action is non-exist
      not :ets.member(:actions, action) -> nil
      # do the work
      true -> callbacks = :ets.lookup_element(:actions, action, 2) # Step 1.
              Enum.each(callbacks, fn func -> func.(args) end) # Step 2.
    end
  end

end
