import React from 'react';
import api from '../redux/api';
import store from '../redux/store';
import socket from '../socket';
import utils from '../redux/utils';

export default function ConfigPanelBuy(props) {
  let style = {
    symbol: {
      color: "dodgerblue",
      fontWeight: "bold",
      textDecoration: "underline",
    },
    dollarsign: {
      position: "absolute",
      fontWeight: "bold",
      color: "#000080",
      transform: "translate3d(5px, 4px, 0)",
    },
    label: {
      // fontSize: "larger",
      paddingRight: "0.5em",
      fontWeight: "bold",
      width: "80px",
      textAlign: "right",
    },
    input: {
      width: "80px",
      height: "2em",
      borderRadius: "5%",
      paddingLeft: "1em",
    },
    submit_button: {
      marginTop: "30px",
      width: "50%",
    },
    errorText: {
      display: "none",
      // border: ".5px solid red",
      // color: "red",
      // fontWeight: "bold",
    },
  };
  style.stoploss = style.buyprice = style.input;
  style.quantity = {...style.input, paddingLeft: ".3em"};

  let buypriceInput = React.createRef();
  let quantityInput = React.createRef();
  let stoplossInput = React.createRef();
  let errorTextEl   = React.createRef();

  function confirmBuy() {
    __clearErrorMessage();
    if (_validate()){
      /**
      * 1. place the order through the given channel
      * 2. dismiss component
      */
      let price = parseFloat(buypriceInput.current.value);
      let qty = parseInt(quantityInput.current.value);
      let stoploss = parseFloat(stoplossInput.current.value);
      props.submit(price, qty, stoploss);
      props.dismiss();
    }
  }

  /** Validates all the inputs
  * () => boolean
  */
  function _validate(){
    /**
    * stoploss < price
    **/
    let price = buypriceInput.current.value;
    let qty = quantityInput.current.value;
    let stoploss = stoplossInput.current.value;

    let all_pass = true;

    if (!price){
      props.animate_error(buypriceInput.current);
      all_pass = false;
    }
    if ( !qty || (parseInt(qty) != parseFloat(qty)) ) {
      props.animate_error(quantityInput.current);
      all_pass = false;
    }
    if (stoploss){
      if (stoploss >= price){
        props.animate_error(stoplossInput.current);
        all_pass = false;
      }
    }
    if (all_pass && _notEnoughBalance()){
      __setAndShowErrorMessage("Not enough balance to cover the purchase");
      props.animate_error(errorTextEl.current);
      all_pass = false;
    }

    return all_pass;
  }

  function __setAndShowErrorMessage(msg){
    errorTextEl.current.textContent = msg;
    errorTextEl.current.style.display = "block";
  }
  function __clearErrorMessage(){
    errorTextEl.current.style.display = "none";
  }

  // Return: boolean
  function _notEnoughBalance(){
    let price = buypriceInput.current.value;
    let qty = quantityInput.current.value;
    let balance = utils.getUsableBalance();
    console.log(balance);

    return balance < (price * qty);
  }

  return (
    <React.Fragment>
      <h2>
        <span className="text-success">Buy </span>
        <span style={style.symbol}>{ props.symbol }</span>
      </h2>
      <p>
        <label htmlFor="buy.at" style={style.label}>at</label>
        <span style={style.dollarsign}>$</span>
        <input id="buy.at" className="config-panel-field" type="number" style={style.buyprice} ref={ buypriceInput } />
      </p>
      <p>
        <label htmlFor="buy.qty" style={style.label}>quantity</label>
        <input id="buy.qty" className="config-panel-field" type="number" style={style.quantity} ref={ quantityInput } />
      </p>
      <p>
        <label htmlFor="buy.stoploss" style={style.label}>stoploss</label>
        <span style={style.dollarsign}>$</span>
        <input id="buy.stoploss" className="config-panel-field" type="number" style={style.stoploss} ref={ stoplossInput } />
      </p>
      <div className="config-panel-field alert alert-danger" style={style.errorText} ref={errorTextEl}>
      </div>
      <button className="btn btn-success btn-lg" style={style.submit_button} onClick={confirmBuy}>Confirm</button>
    </React.Fragment>
  );
}
