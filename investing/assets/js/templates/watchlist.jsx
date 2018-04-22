import React, { Component } from 'react';
import { connect } from 'react-redux';
import socket from '../socket';
import api from '../redux/api';
import store from '../redux/store';

export default connect( state_map )( class Watchlist extends Component {
  constructor(props){
    super(props);
    this.channelInit();
    api.request_assets(window.userToken, () => {
        if (store.getState().assets.length > 0)
          this.channel.push("batch_subscribe", {token: window.userToken, assets: store.getState().assets});

    });
  }

  render(){

    let style = {};
    style.container = {
      paddingBottom: "131px",
    };

    /**
    * props.assets = [...{symbol, last_price, change, percent_change, market_cap}...]
    ***/
    if (this.props.assets.length){
      return (
        <div style={style.container}>
          <h2>Watchlist</h2>
          <table className="table">
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Last Price</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {
                this.props.assets.map( (asset) => <WatchlistEntry asset={ asset } removeAsset={this.removeAsset.bind(this)} key={ asset.id } /> )
              }
            </tbody>
          </table>
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
    this.channel = socket.channel(`watchlist:${window.userToken}`);
    this.channel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join room channel", resp) });

    this.channel.on("update_asset_price", (asset) => {
      store.dispatch({
        type: "UPDATE_ASSET_PRICE",
        asset: asset
      })
    });
    console.log(this.props);
  }

  // componentDidMount(){
  //   console.log("compoent did mount", this.props.assets);
  //   if (this.props.assets.length > 0)
  //     this.channel.push("batch_subscribe", {token: window.userToken, assets: this.props.assets});
  //
  // }

  removeAsset(asset) {
    api.delete_asset(window.userToken, asset);

    this.channel.push("unsubscribe", {token: window.userToken, asset: asset});
  }
} );

function state_map(state) {
  return {
    assets: state.assets,
  };
}

function WatchlistEntry(props) {
  let style = {};
  style.symbol = {color: "dodgerblue", fontWeight: "bold"};
  style.price  = {
    color: props.asset.price_color,
    fontWeight: "bold",
  };
  style.close_btn = {borderRadius: "50%", padding: "2px", fontSize: "1.5rem", fontWeight: 700, lineHeight: 1, color: "#000", textShadow: "0 1px 0 #fff", opacity: .5, width: "1.5em", height: "1.5em"};
  style.close_txt = {verticalAlign: "text-top"};

  return (
    <tr>
      <td style={style.symbol}>{ props.asset.symbol }</td>
      <td style={style.price }>{ props.asset.price }</td>
      <td>
        <button type="button" style={style.close_btn} aria-label="Close" onClick={ () => props.removeAsset(props.asset) }>
          <span aria-hidden="true" style={style.close_txt}>&times;</span>
        </button>
      </td>
    </tr>
  );
}
