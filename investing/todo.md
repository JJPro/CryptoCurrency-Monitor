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
1. handle order cancellation, which can only happen on pending orders 
	- order channel ✅
	- actions ✅
	- order manager ✅
2. append uid to action name, so that user channels only receive action messagse of their own orders. 
	two approaches: 
	2.1 broadcast to action+uid inside order manager, 
		this approach will isolate your actions pattern
	2.2 without using broadcast, just update the action name to include uid