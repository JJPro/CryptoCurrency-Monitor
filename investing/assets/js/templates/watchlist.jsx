import React, { Component } from 'react';
import { connect } from 'react-redux';
import socket from '../socket';
import api from '../redux/api';
import store from '../redux/store';


export default connect( state_map )( class Watchlist extends Component {
  constructor(props){
    super(props);
    this.channel = props.channel;
    this.channelInit();

    if (window.userToken){
      api.request_assets(window.userToken, () => {
        if (store.getState().assets.length > 0)
        this.channel.push("batch_subscribe", {token: window.userToken, assets: store.getState().assets});

      });
    }
  }

  render(){

    let style = {};

    /**
    * props.assets = [...{symbol, last_price, change, percent_change, market_cap}...]
    ***/
    if (this.props.assets.length){
      return (
        <div>
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
                this.props.assets.map( (asset) => <WatchlistEntry asset={ asset } removeAsset={this.removeAsset.bind(this)} configAlert={this.configAlert.bind(this)} key={ asset.id } /> )
              }
            </tbody>
          </table>
        </div>
      );
    } else {
      return (
        <div className="jumbotron text-center">
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
    .receive("error", resp => { console.log("Unable to join watchlist channel", resp) });

    this.channel.on("update_asset_price", (asset) => {
      store.dispatch({
        type: "UPDATE_ASSET_PRICE",
        asset: asset
      })
    });
    // console.log(this.props);
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

  configAlert(asset) {
    store.dispatch({
      type: "SET_ALERT",
      alert: {symbol: asset.symbol}
    });
    document.querySelector('.alert-cover').classList.add("active");
    document.querySelector('.alert-panel').classList.add("active");
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
  style.close_btn = {borderRadius: "50%", padding: "2px", fontSize: "1.5rem", fontWeight: 700, lineHeight: 1, color: "#000", textShadow: "0 1px 0 #fff", opacity: .5, width: "1.5em", height: "1.5em", marginRight: "15px",};
  style.close_txt = {verticalAlign: "text-top"};
  style.alert_btn = {...style.close_btn};
  style.actioncell = {
    // display: "flex", alignItems: "center", justifyContent: "space-around",
  }

  return (
    <tr>
      <td style={style.symbol}>{ props.asset.symbol }</td>
      <td style={style.price }>{ props.asset.price }</td>
      <td style={style.actioncell}>
        <button type="button" style={style.close_btn} aria-label="Close" onClick={ () => props.removeAsset(props.asset) }>
          <svg fill="#000000" height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
    <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
    <path d="M0 0h24v24H0z" fill="none"/>
</svg>

        </button>
        <button type="button" className="" style={style.alert_btn} aria-label="Set Alert" onClick={ () => props.configAlert(props.asset) }>
          <svg fill="#000000" height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
            <path d="M0 0h24v24H0V0z" fill="none"/>
            <path d="M10.01 21.01c0 1.1.89 1.99 1.99 1.99s1.99-.89 1.99-1.99h-3.98zm8.87-4.19V11c0-3.25-2.25-5.97-5.29-6.69v-.72C13.59 2.71 12.88 2 12 2s-1.59.71-1.59 1.59v.72C7.37 5.03 5.12 7.75 5.12 11v5.82L3 18.94V20h18v-1.06l-2.12-2.12zM16 13.01h-3v3h-2v-3H8V11h3V8h2v3h3v2.01z"/>
        </svg>

        </button>
      </td>
    </tr>
  );
}
