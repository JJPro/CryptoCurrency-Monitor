defmodule Investing.Utils.TestActions do
  @moduledoc """
  Discoveries:
  1. the action callback function can be private
  2. you can call private functions inside the callback.
  """

  alias Investing.Utils.Actions


  def test do
    action = :order_placed
    Actions.add_action(action, &echo_order/1)
  end

  defp echo_order(order: order, price: current_price, condition: condition) do
    IO.inspect(order, label: "order is:")
    IO.puts "current price: #{current_price}"
    IO.puts "condition is: #{condition}"
    private()
  end

  defp private do
    IO.puts "This is private function inside #{__MODULE__}"
  end
end

defmodule Investing.Utils.TestActions2 do
  alias Investing.Finance
  alias Investing.Utils.Actions

  # def test_private do
  #   Investing.Utils.TestActions.private()
  # end
  def test do

    order = Finance.get_order!(4)
    action = :order_placed
    Actions.do_action action, order: order, price: 28, condition: ">= 25"
  end
end
