import React, { Component } from 'react';
import { connect } from 'react-redux';
import api from '../redux/api';
import socket from '../socket';

export default connect(state_map)(props => {
  let style = {};
  style.container = {
    position: "fixed",
    top: 0,
    right: 0,
    zIndex: 1200,
    width: "300px",
    height: "100vh",
    background: "white",
    padding: "20px 15px",
    textAlign: "center",
    display: "flex",
    flexDirection: "column",
    justifyContent: "center",
    alignItems: "center",
    boxShadow: "0 2px 3px 0 #e6e6e6",
    transition: "all 0.5s",
    // transform: "translate3d(120%, 0, 0)",
    // opacity: 0,
  };
  style.symbol = {
    color: "dodgerblue",
    fontWeight: "bold",
    textDecoration: "underline",
  };
  style.select = {
    width: "40px",
    height: "2em",
    textAlign: "center",
    marginRight: "1em",
  };
  style.input = {
    width: "80px",
    height: "2em",
    borderRadius: "5%",
    paddingLeft: "1em",
  };
  style.dollarsign = {
    position: "absolute",
    fontWeight: "bold",
    color: "#00000080",
    transform: "translate3d(5px, 4px, 0)",
  };
  style.submit_button = {
    marginTop: "30px",
    width: "50%",
  };
  style.alert_cover = {
    position: "absolute", top: 0, left: 0,
    width: "100vw",
    height: "100vh",
    background: "rgba(0, 0, 0, .5)",
    zIndex: 1100,
    transition: "opacity .5s",
  };

  let refs = {};

  function submitAlert(alert) {
    /*** NOTE:
     * This *alert* argument is of structure of
     * as defined in reducer-alert-panel
     * It MUST BE converted to format/fields conforming to backend alert schema
     * before submitting to server
    **** NOTEEND */

    // validate threshold field
    if (alert.threshold.trim()){
      // convert: {symbol, threshold, condition} ==> {symbol, condition}
      let condition = `${alert.condition} ${alert.threshold}`;
      api.add_alert(window.userToken, alert.symbol, condition, () => {
        // TODO: subscribe to real update
        let channel = socket.channel(`watchlist:${window.userToken}`);
        channel.join()
        .receive("ok")
        .receive("error", resp => { console.log("Unable to join watchlist channel", resp) });

        console.log(">>>>> subscribing to real time update of ", alert.symbol);
        channel.push("subscribe", {token: window.userToken, asset: {symbol: alert.symbol}});
        dismissAlertPanel();
      });

    } else {
      // threshold is empty, alert by shaking the input box
      refs.threshold.classList.add("error");
      refs.threshold.addEventListener("animationend", () => {
        refs.threshold.classList.remove("error");
      });
    }
  }

  function dismissAlertPanel() {
    refs.container.classList.remove("active");
    refs.alert_cover.classList.remove("active");
  }

  function changeCondition(ev) {
    let condition = ev.target.value;
    store.dispatch({
      type: "UPDATE_ALERT",
      alert: {condition}
    });
  }

  function changeThreshold(ev) {
    let threshold = ev.target.value;
    store.dispatch({
      type: "UPDATE_ALERT",
      alert: {threshold}
    });
  }

  return (
    <div>
      <div className="alert-cover" style={style.alert_cover} ref={ el => refs.alert_cover = el } onClick={dismissAlertPanel}></div>
      <div className="alert-panel" style={style.container} ref={ el => refs.container = el }>
        <h2>Notify me when <span style={style.symbol}>{props.alert.symbol}</span> is: </h2>
        <div>
          <select style={style.select} value={props.alert.condition} onChange={changeCondition}>
            <option value=">">&#62;</option>
            <option value="<">&#60;</option>
          </select>
          <span style={style.dollarsign}>$</span>
          <input className="alert-panel-threshold" type="number" style={style.input} ref={ el => refs.threshold = el } value={props.alert.threshold} onChange={changeThreshold} />
        </div>
        <button className="btn btn-success btn-lg" style={style.submit_button} onClick={ () => submitAlert(props.alert) }>Alert Me</button>
        <p className="description mt-3 text-muted font-weight-light">Alerts will be sent to your email when condition is met.</p>
      </div>
    </div>
  );
});

function state_map(state) {
  return {alert: state.alert_panel};
}
