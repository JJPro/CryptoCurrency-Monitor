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
    this.channel = socket.channel(`action_pannel:${"kk"}`);
    this.channel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join action_pannel channel", resp) });

    this.channel.on("update_current_asset", (asset) => {
      store.dispatch({
        type: "SET_CURRENT_ASSET",
        asset: asset
      });
    });
  }

  onChangeSymbol(ev) {
    let symbol = ev.target.value;
    if (symbol)
      api.lookup_asset(symbol);
    else
      store.dispatch({
        type: "CLEAR_PROMPTS"
      });
  }

  render(){
    let style = {};
    style.panel = {
      borderTop: "1px solid lightgray",
      backgroundColor: "white",
    };

    style.price = {
      color: this.props.current_asset.price_color,
      padding: "5px",
      minWidth: "4em",
      display: "inline-block",
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

    /**
    * props.current_asset = {
    symbol: string,
    prompts: [...{symbol, name, market}...],
    price: number,
    price_color: string
    }
    */

    return (
      <div className="fixed-bottom container-fluid d-flex justify-content-around align-items-center py-5" style={style.panel}>
        <div className="mr-5" style={style.search_field_wrapper}>
          {
            (() => {
              if (this.props.current_asset.prompts.length){
                return (
                  <div className="dropdown-menu" style={style.dropdown_menu}>
                    {
                      this.props.current_asset.prompts.map( (prompt) => {
                        return <Prompt prompt={prompt} channel={this.channel} key={prompt.name} />
                      })
                    }
                  </div>

                );
              }
            })()
          }
          <input type="text" className="form-control" placeholder="Symbol" onChange={ this.onChangeSymbol.bind(this) } />
        </div>
        <div className="mr-5">
          <label for="price">Price: </label>
          <span style={ style.price }>{this.props.current_asset.value}</span>
        </div>
        <button className="btn btn-info">Watch</button>
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
    props.channel.push("symbol select", {symbol: prompt.symbol});
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
