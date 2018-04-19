import React, { Component } from 'react';
import { connect } from 'react-redux';
import socket from '../socket';
// import api from '../api';
import store from '../redux/store';

// TODO: may need to transfer to a functional component
export default connect( state_map )( class Watchlist extends Component {
  constructor(props){
    super(props);

    this.channel = props.channel;
    this.channelInit();
  }

  render(){

    let style = {};

    /**
    * props.assets = [...{symbol, last_price, change, percent_change, market_cap}...]
    ***/
    if (this.props.assets.length){
      return (
        <div>
        </div>
      );
    } else {
      return (
        <div className="jumbotron">
          <h2>Welcome to JJPro Market Watcher</h2>
          <p className="lead">Add items to your watchlist to get live updates and setting email alerts.</p>
        </div>
      );
    }
  }

  channelInit() {
    this.channel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join room channel", resp) });
  }
} );

function state_map(state) {
  return {
    assets: state.assets,
  };
}
