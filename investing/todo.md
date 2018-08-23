TODO:
- order manager ✅
- test actions.ex ✅
- put do_action() into appropriate places like alert_mamanger and order_manager ✅
- channels and frontend

### Debugging
:debugger.start
:int.ni(Investing.Finance.ThresholdManager)



Order_channel JS:
the frontend is going to handle these messsages:
- "init order list", {active: [orders], inactive: [orders]}
- "add order", {order: order}
- "update order status", {order: order}


Caveats:
- use @derive attr for Order's schema if JSON encoding issues occur.



TODO:

api.js, alert-controller:
	use broadcast to push new alert to the front end.
	This assures alerts open on another window is also updated.



