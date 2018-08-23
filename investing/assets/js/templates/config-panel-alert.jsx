import React from 'react';
import api from '../redux/api';
import store from '../redux/store';

export default function ConfigPanelAlert(props){
  let style = {
    symbol: {
      color: "dodgerblue",
      fontWeight: "bold",
      textDecoration: "underline",
    },
    select: {
      width: "40px",
      height: "2em",
      textAlign: "center",
      marginRight: "1em",
    },
    input: {
      width: "80px",
      height: "2em",
      borderRadius: "5%",
      paddingLeft: "1em",
    },
    dollarsign: {
      position: "absolute",
      fontWeight: "bold",
      color: "#000080",
      transform: "translate3d(5px, 4px, 0)",
    },
    submit_button: {
      marginTop: "30px",
      width: "50%",
    },
  };

  let condition = React.createRef();
  let threshold = React.createRef();
  let alert = {symbol: props.symbol, condition: ">", threshold: ""};

  function changeCondition(ev) {
    alert.condition = condition.current.value;
    // console.log("alert", alert);
  }

  function changeThreshold(ev) {
    alert.threshold = threshold.current.value;
    // console.log("alert", alert);
  }


  function submitAlert() {

    if (_validate()){
      // API call accepts format:  > 200
      // convert: {symbol, threshold, condition} ==> {symbol, condition}
      let condition = `${alert.condition} ${alert.threshold}`;
      props.submit(condition);
      props.dismiss();
    }
  }

  function _validate(){
    if (alert.threshold.trim()){
      return true;
    } else {
      props.animate_error(threshold.current);
      return false;
    }
  }

  return <React.Fragment>
    <h2>Notify me when <span style={style.symbol}>{props.symbol}</span> is: </h2>
    <div>
      <select style={style.select} ref={condition} onChange={changeCondition}>
        <option value=">">&#62;</option>
        <option value="<">&#60;</option>
      </select>
      <span style={style.dollarsign}>$</span>
      <input className="config-panel-field" type="number" style={style.input} ref={threshold} onChange={changeThreshold} />
    </div>
    <button className="btn btn-success btn-lg" style={style.submit_button} onClick={submitAlert}>Alert Me</button>
    <small className="mt-3 text-muted form-text">Alerts will be sent to your email when condition is met.</small>
  </React.Fragment>
}
