import store from './store';
import socket from '../socket';

class Utils {
  configAlert(symbol) {
    store.dispatch({
      type: "CONFIG_ASSET",
      config_options: {symbol: symbol, type: "alert"}
    });
  }

  configBuy(symbol) {
    let action_channel = socket.channels.find((ch) => ch.topic.startsWith("action_panel"));
    store.dispatch({
      type: "CONFIG_ASSET",
      config_options: {
        symbol: symbol,
        type: "buy",
        submit: (price, qty, stoploss) => action_channel.push("place order", {action: "buy", target: price, symbol: symbol, quantity: qty, stoploss: stoploss}),
      }
    });
  }

  configSell(symbol) {
    let action_channel = socket.channels.find((ch) => ch.topic.startsWith("action_panel"));
    store.dispatch({
      type: "CONFIG_ASSET",
      config_options: {
        symbol: symbol,
        type: "sell",
        submit: (price, qty) => action_channel.push("place order", {action: "sell", target: price, symbol: symbol, quantity: qty}),
      }
    });
  }

  getUsableBalance(){
    return store.getState().balance.usable;
  }

  getHoldingsCount(symbol){
    return store.getState().holdings.reduce(
      (acc, h) => h.symbol == symbol ? acc+h.quantity : acc
      , 0
    );
  }

  // format string
  currencyFormatString(num, printSymbol = false){
    if (printSymbol){
      return num.toLocaleString("en-US", {style: "currency", currency:'USD'});
    } else {
      return num.toLocaleString("en-US");
    }
  }
}

export default new Utils();
