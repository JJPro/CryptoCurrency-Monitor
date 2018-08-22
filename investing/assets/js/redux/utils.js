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

  percentFormatString(num){
    return num.toLocaleString('en-US', {style: 'percent', maximumFractionDigits: 2});
  }

  // modal
  dismissModal(id){
    $(id).modal('hide');
  }

  // show error message on top of window.
  reportError(msg, autoDismiss = true){
    // construct and append error msg container to document if not exists
    let $container = $('#error-container');
    $container = $container.length > 0 ? $container : $('<div id="error-container" class="fixed-top container text-center"></div>');
    $container.appendTo('body');


    // construct error element and append to error container
    let $errMsg = $(`<div class="alert alert-danger fade show inline-block" role="alert" style="max-width: 400px; margin: 0 auto; border-radius: 0;">${msg}</div>`);
    $errMsg.prependTo($container);

    // animate
    $errMsg.hide();
    $errMsg.slideDown();

    // window.err = $errMsg;
    // dismiss
    if (autoDismiss)
      setTimeout(() => $errMsg.alert('close'), 5000);
  }
}

export default new Utils();
