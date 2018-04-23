# Investing

## TODO:

Server To Client Communication:
  - SPA Routes
    - home page / watchlist [no templates]
    - alerts ( manage alerts, show users where the alerts will be sent )
  - Channel
    - ✓ watchlist channel
    - no alerts channel, alerts gets update through watchlist channel
  - JSON
    - list of watched assets -> Assets
    - list of alerts


<!-- Server to Server Communication:
  - WebSockex (Coinbase)
  - Restful (AlphaVantage) -->




<!-- for sockets care about realtime data:
  * implement callback:
   channel.on("update_asset_price", ({symbol, price}) => {})
     ✓ trigger "UPDATE_ASSET_PRICE" -->
