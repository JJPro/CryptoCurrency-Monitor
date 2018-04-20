import React from 'react';
import { connect } from 'react-redux';
// import api from '../api';
// import store from '../store';

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
