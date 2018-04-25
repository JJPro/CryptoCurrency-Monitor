import React, { Component } from 'react';
import { connect } from 'react-redux';
import api from '../redux/api';
import store from '../redux/store';
import socket from '../socket';

export default connect( state_map )( class ActionPanel extends Component {
  constructor(props){
    super(props);

    this.channelInit();
  }

  channelInit(){
    this.channel = socket.channel(`action_panel`, {token: window.userToken});
    this.channel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join action_pannel channel", resp) });

    this.channel.on("update_current_asset", (asset) => {
      store.dispatch({
        type: "UPDATE_CURRENT_ASSET_PRICE",
        asset: asset
      });
    });
  }

  onChangeSymbol(ev) {
    let symbol = ev.target.value;
    if (symbol){
      api.lookup_asset(symbol, () => this.refs.spinner.classList.remove("active"));
      this.refs.spinner.classList.add("active");
    }
    else
      store.dispatch({
        type: "CLEAR_PROMPTS"
      });
  }

  onKeyDown(ev) {
    // press esc to clear prompts
    if (ev.keyCode == 27){
      store.dispatch({type: "CLEAR_PROMPTS"});
      ev.target.value = "";
    }
  }

  addToWatchlist(){
    if (!window.userToken){
      window.location = "/login";
      return;
    }
    api.add_asset(window.userToken, this.props.current_asset.symbol, () => {
      /*** db record creation & redux store insertion success, do the following afterwards:
      * 1. subscribe for price update
      */
      let watchlist_channel = this.channel.socket.channels.find( ch => {return ch.topic.includes("watchlist")});
      if (watchlist_channel) watchlist_channel.push("subscribe", {token: window.userToken, asset: this.props.current_asset});
    });
  }

  render(){
    let style = {};
    style.panel = {
      borderTop: "1px solid lightgray",
      backgroundColor: "white",
    };
    style.symbol = {
      color: "dodgerblue",
      fontWeight: "bold",
    };
    style.price = {
      color: this.props.current_asset.price_color,
      padding: "5px",
      minWidth: "4em",
      display: "inline-block",
      fontWeight: "bold",
    };
    style.search_field_wrapper = {
      position: "relative",
    };
    style.dropdown_menu = {
      position: "absolute",
      display: "block",
      transform: "translateY(-100%)",
      top: "-1px",
    };
    style.spinner = {
      position: "absolute",
      right: "10px",
      top: "40%",
      display: "flex",
      width: "45px",
      justifyContent: "space-between",
    }

    /**
    * props.current_asset = {
    symbol: string,
    prompts: [...{symbol, name, market}...],
    price: number,
    price_color: string
    }
    */

    return (
      <div className="fixed-bottom container-fluid" style={style.panel}>
        <div className="container d-flex justify-content-around align-items-center py-5">
          <div className="mr-5" style={style.search_field_wrapper}>
            {
              (() => {
                if (this.props.current_asset.prompts.length){
                  return (
                    <div className="dropdown-menu" style={style.dropdown_menu}>
                      {
                        this.props.current_asset.prompts.map( (prompt) => {
                          return <Prompt prompt={prompt} old_symbol={this.props.current_asset.symbol} channel={this.channel} key={prompt.name} />
                        })
                      }
                    </div>

                  );
                }
              })()
            }
            <input type="text" className="form-control" placeholder="Symbol" onChange={ this.onChangeSymbol.bind(this) } onKeyDown={ this.onKeyDown.bind(this) } />
            <div className="spinner" style={style.spinner} ref="spinner" >
              <div className="bounce1"></div>
              <div className="bounce2"></div>
              <div className="bounce3"></div>
            </div>
          </div>
          <div className="mr-5">
            <span>Symbol: </span>
            <span style={ style.symbol }> {this.props.current_asset.symbol}</span>
          </div>
          <div className="mr-5">
            <span>Price: </span>
            <span style={ style.price }>$ {this.props.current_asset.price}</span>
          </div>
          <button className="btn btn-info" onClick={ this.addToWatchlist.bind(this) } disabled={ this.props.current_asset.symbol.length == 0 } >Watch</button>
        </div>
      </div>
    );
  }
} );

function state_map(state) {
  return {
    current_asset: state.current_asset,
  };
}

function Prompt(props) {
  let style = {};
  style.symbol = {color: "dodgerblue"};
  style.name = {color: "auto", margin: "5px auto", fontWeight: "lighter"};
  style.market = {marginLeft: "20px", fontWeight: "lighter"};

  function set_as_current_asset(prompt) {
    // channel.push(....)
    // inform server to send us realtime update about this symbol
    // channel.on to trigger Action to update current asset, this is done in channelInit

    // unsubscribe for previous asset's update
    // subscribe for new asset's update
    props.channel.push("symbol select", {old_symbol: props.old_symbol, new_symbol: prompt.symbol, market: prompt.market, token: window.userToken});
    store.dispatch({
      type: "SET_CURRENT_ASSET",
      asset: {symbol: prompt.symbol, market: prompt.market}
    });
  }

  return (
    <div className="dropdown-item" onClick={() => set_as_current_asset(props.prompt)}>
      <div className="d-flex justify-content-between align-items-center">
        <strong style={style.symbol}>{ props.prompt.symbol }</strong> <span className="float-right" style={ style.market }>{ props.prompt.market }</span>
      </div>
      <p style={ style.name }>{ props.prompt.name }</p>
    </div>
  );
}
