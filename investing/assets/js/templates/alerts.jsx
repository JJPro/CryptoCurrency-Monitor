import React, { Component } from 'react';
import { connect } from 'react-redux';
import api from '../redux/api';
import store from '../redux/store';
import socket from '../socket';

export default connect( state_map )( class Alerts extends Component {
  constructor(props) {
    super(props);
    this.channel = props.channel;
    this.channelInit(); // take advantage of watchlist channel to update prices
  }

  removeAlert(alert) {
    api.delete_alert(window.userToken, alert, () => {
      // unsub from real-time updates for optimization, but this is trivial
      let active_alerts = this.props.alerts.filter((a) => !a.expired);
      if ( ! active_alerts.find((a) => a.symbol == alert.symbol) ){
        this.channel.push("unsubscribe", {token: window.userToken, alert: alert});
      }
    });
  }

  channelInit(){
    this.channel = socket.channel(`alert:${window.userToken}`);
    this.channel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join watchlist channel from alerts page", resp) });

    this.channel.on("update_asset_price", (asset) => {
      // console.log(">>>>> price update", asset.symbol);
      store.dispatch({
        type: "UPDATE_ALERT_PRICE",
        alert: asset
      });
    });

    if (window.userToken){
      api.request_alerts(window.userToken, () => {
        // console.log(">>>>>>>>>> pushing batch subscribe");
        this.channel.push("batch_subscribe", {token: window.userToken, alerts: this.props.alerts.filter((a) => !a.expired)});
      });
    }
  }

  render() {

    let style = {};

    /**
    * props.alerts = [...{symbol, last_price, condition}...]
    */
    return (
      <div>
        <div>
          <h2>Active Alerts</h2>
          <table className="table">
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Last Price</th>
                <th>Condition</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {
                this.props.alerts.filter((alert) => !alert.expired).map(
                  (alert) => <AlertEntry alert={ alert } removeAlert={ this.removeAlert.bind(this) } key={ alert.id } /> )
              }
            </tbody>
          </table>

        </div>
        <div>
          <h2>Expired Alerts</h2>
          <table className="table">
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Condition</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {
                this.props.alerts.filter((alert) => alert.expired).map( (alert) => <AlertEntry alert={ alert } removeAlert={ this.removeAlert.bind(this) } key={ alert.id } /> )
              }
            </tbody>
          </table>

        </div>
      </div>
    );
  }
} );

function state_map(state) {
  return {
    alerts: state.alerts,
  };
}

function AlertEntry(props) {

  let style = {};
  style.symbol = {color: "dodgerblue", fontWeight: "bold"};
  style.price  = {
    color: props.alert.price_color,
    fontWeight: "bold",
  };
  style.close_btn = {borderRadius: "50%", padding: "2px", fontSize: "1.5rem", fontWeight: 700, lineHeight: 1, color: "#000", textShadow: "0 1px 0 #fff", opacity: .5, width: "1.5em", height: "1.5em", marginRight: "15px",};
  style.close_txt = {verticalAlign: "text-top"};

  return (
    <tr>
      <td style={style.symbol}>{ props.alert.symbol }</td>
      {!props.alert.expired && <td style={style.price }>{ props.alert.price }</td>}
      <td style={style.condition}>{ props.alert.condition }</td>
      <td style={style.actioncell}>
        <button type="button" style={style.close_btn} aria-label="Close" onClick={ () => props.removeAlert(props.alert) }>
          <span aria-hidden="true" style={style.close_txt}>&times;</span>
        </button>
      </td>
    </tr>
  );
}
