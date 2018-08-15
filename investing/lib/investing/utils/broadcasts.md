This File keeps track of all the broadcast message calls
Gives a hint about what arguments are the handlers supposed to accept

TODO:
The client need to handle the following messages:

Target channel           event       message
order:#{uid}        "order_placed"    %{order: order}
                    "order_canceled"  %{order: order}
                    "order_executed"  %{order: order, at_price: price, condition: condition}
holding:#{uid}      "holding_updated" %{holding: holding, action: :increase/:decrease/:delete}
                    "balance_updated" %{new_balance: balance, action: :add/:subtract, amt: change_amt}
alert:#{uid}        TODO deal with alerts later.
