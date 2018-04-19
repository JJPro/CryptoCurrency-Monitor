import React from 'react';
import { connect } from 'react-redux';
// import api from '../api';
// import store from '../store';

export default connect( state_map )( (props) => {
  let style = {};
  style.panel = {
    borderTop: "1px solid lightgray",
    // display: "flex",
  };

  style.price = {
    color: props.current_asset.price_color,
  };

  let onChangeSymbol = ( ev ) => {
    // TODO: trigger api function to search for entered term, which will then trigger redux state update
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
    <div className="fixed-bottom d-flex justify-content-center" style={style.panel}>
      <div className="form-group mb-2">
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
      <div className="form-group mb-2">
        <label for="price" className="sr-only">Price: </label>
        <input type="text" readonly className="form-control-plaintext" id="price" value={props.current_asset.value} style={ style.price } />
      </div>
      <button className="btn btn-info mb-2">Watch</button>
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
  style.name = {color: "lightgray"};
  style.market = {...style.name, };
  return (
    <div className="dropdown-item">
      <strong>{ props.prompt.symbol }</strong> <span className="float-right" style={ style.market }>{ props.prompt.market }</span>
      <p style={ style.name }>{ props.prompt.name }</p>
    </div>
  );
}
