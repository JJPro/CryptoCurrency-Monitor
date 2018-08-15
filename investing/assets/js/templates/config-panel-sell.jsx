import React from 'react';
import api from '../redux/api';
import store from '../redux/store';
import utils from '../redux/utils';

export default function ConfigPanelSell(props) {
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
    },
  };
  style.sellprice = style.input;
  style.quantity = {...style.input, paddingLeft: ".3em"};

  let sellpriceInput = React.createRef();
  let quantityInput = React.createRef();
  let errorTextEl   = React.createRef();

  function confirmSell() {
    __clearErrorMessage();
    if (_validate()){
      let price = parseFloat(sellpriceInput.current.value);
      let qty = parseInt(quantityInput.current.value);

      props.submit(price, qty);
      props.dismiss();
    }
  }

  function _validate(){
    let price = sellpriceInput.current.value;
    let qty = quantityInput.current.value;

    let all_pass = true;

    // check presence of price
    if (!price){
      props.animate_error(sellpriceInput.current);
      all_pass = false;
    }
    // check presence of qty and that it is integer value
    if ( !qty || (parseInt(qty) != parseFloat(qty)) ) {
      props.animate_error(quantityInput.current);
      all_pass = false;
    }
    if (all_pass && _notEnoughHoldingsToSell()){
      __setAndShowErrorMessage("Not enough holdings to sell");
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
  function _notEnoughHoldingsToSell(){
    let qtyToSell = quantityInput.current.value;
    return qtyToSell > utils.getHoldingsCount(props.symbol);
  }

  return (
    <React.Fragment>
      <h2>
        <span className="text-danger">Buy </span>
        <span style={style.symbol}>{ props.symbol }</span>
      </h2>
      <p>
        <label htmlFor="sell.at" style={style.label}>at</label>
        <span style={style.dollarsign}>$</span>
        <input id="sell.at" className="config-panel-field" type="number" style={style.sellprice} ref={ sellpriceInput } />
      </p>
      <p>
        <label htmlFor="sell.qty" style={style.label}>quantity</label>
        <input id="sell.qty" className="config-panel-field" type="number" style={style.quantity} ref={ quantityInput } />
      </p>
      <div className="config-panel-field alert alert-danger" style={style.errorText} ref={errorTextEl}>
      </div>
      <button className="btn btn-danger btn-lg" style={style.submit_button} onClick={confirmSell}>Confirm</button>
    </React.Fragment>
  )
}
