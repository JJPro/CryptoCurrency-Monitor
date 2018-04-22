import React from 'react';
import { connect } from 'react-redux';
import api from '../redux/api';
import store from '../redux/store';
import socket from '../socket';


let channel = socket.channel(`watchlist:${window.userToken}`);
channel.join()
.receive("ok")
.receive("error", resp => { console.log("Unable to join watchlist channel", resp) });

channel.on("update_asset_price", (asset) => {
  store.dispatch({
    type: "UPDATE_ALERT_PRICE",
    alert: asset
  });
});

api.request_alerts(window.userToken, () => {
  channel.push("batch_subscribe", {token: window.userToken, assets: store.getState().alerts});
});

export default connect( state_map )( (props) => {
  let style = {};

  /**
   * props.alerts = [...{symbol, last_price, condition}...]
   */
  return (
    <div>
      <h2>Alerts</h2>
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
              props.alerts.map( (alert) => <AlertEntry alert={ alert } key={ alert.name } /> )
            }
          </tbody>
        </table>

    </div>
  );
} );

function state_map(state) {
  return {
    alerts: state.alerts,
  };
}

function AlertEntry(props) {
  return (
    <tr>
      <td>{ props.alert.symbol }</td>
      <td>{ props.alert.last_price }</td>
      <td>{ props.alert.condition }</td>
      <td>x</td>
    </tr>
  );
}
