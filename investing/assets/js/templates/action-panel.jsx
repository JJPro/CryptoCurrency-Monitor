import React from 'react';
import { connect } from 'react-redux';
import api from '../redux/api';
import store from '../redux/store';

export default connect( state_map )( (props) => {
  let style = {};
  style.panel = {
    borderTop: "1px solid lightgray",
    // display: "flex",
  };

  style.price = {
    color: props.current_asset.price_color,
    padding: "5px",
    minWidth: "4em",
    display: "inline-block",
  };

  let onChangeSymbol = ( ev ) => {
    // TODO: trigger api function to search for entered term, which will then trigger redux state update
    let symbol = ev.target.value;
    // api.search_symbol(symbol);
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
      <div className="mr-5">
        {
          (() => {
            if (props.current_asset.prompts){
              return (
                <div className="dropdown-menu">
                  {
                    props.current_asset.prompts.map( (prompt) => {
                      return <Prompt prompt={prompt} key={prompt.name} />
                    })
                  }
                </div>

              );
            }
          })()
        }
        <input type="text" className="form-control" placeholder="Symbol" onChange={ onChangeSymbol } />
      </div>
      <div className="mr-5">
        <label for="price">Price: </label>
        <span style={ style.price }>{props.current_asset.value}</span>
      </div>
      <button className="btn btn-info mr-5">Watch</button>
    </div>
  );
} );

function state_map(state) {
  return {
    current_asset: state.current_asset,
  };
}

function Prompt(props) {
  let style = {};
  style.symbol = {color: "dodgeblue"};
  style.name = {color: "lightgray"};
  style.market = {...style.name, };
  return (
    <div className="dropdown-item">
      <strong style={style.symbol}>{ props.prompt.symbol }</strong> <span className="float-right" style={ style.market }>{ props.prompt.market }</span>
      <p style={ style.name }>{ props.prompt.name }</p>
    </div>
  );
}
