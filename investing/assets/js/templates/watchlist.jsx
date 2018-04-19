import React from 'react';
import { connect } from 'react-redux';
// import api from '../api';
// import store from '../store';

export default connect( state_map )( (props) => {
  let style = {};

  /**
   * props.assets = [...{symbol, last_price, change, percent_change, market_cap}...]
   */
  return (
    <div></div>
  );
} );

function state_map(state) {
  return {
    assets: state.assets,
  };
}
