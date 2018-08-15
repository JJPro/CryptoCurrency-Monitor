import React, { Component } from 'react';
import { connect } from 'react-redux';
import store from '../redux/store';
import ConfigPanelAlert from './config-panel-alert';
import ConfigPanelBuy from './config-panel-buy';
import ConfigPanelSell from './config-panel-sell';

export default connect(state_map)(class ConfigPanel extends Component {
  constructor(props) {
    super(props);
    this.panel_matte = React.createRef();
    this.panel = React.createRef();

    this.dismiss = this.dismiss.bind(this);
    this.animate_error = this.animate_error.bind(this);
  }

  _show(){
    this.panel_matte.current.classList.add("active");
    this.panel.current.classList.add("active");
  }
  _dismiss() {
    this.panel_matte.current.classList.remove("active");
    this.panel.current.classList.remove("active");
  }
  animate_error(el){
    el.classList.add("error");
    el.addEventListener("animationend", () => {
      el.classList.remove("error");
    });
  }
  dismiss() {
    this._dismiss();
    setTimeout(() => store.dispatch({type: "CLEAR_CONFIG"}), 100);
    // CLEAR_CONFIG to trigger a rerender, otherwise component won't rerender correctly when clicking on the same alert button.
  }
  componentDidUpdate(){
    if (this.props.show)
      this._show();
    // else
    //   this._dismiss();
  }

  render(){

    let style = {

      panel: {
        position: "fixed", top: 0, right: 0,
        zIndex: 1200,
        width: "300px", height: "100vh",
        background: "white",
        padding: "20px 15px",
        textAlign: "center",
        display:"flex",flexDirection:"column",justifyContent:"center",alignItems:"center",
        boxShadow: "0 2px 3px 0 #e6e6e6",
        transition: "all 0.5s",
        // transform: "translate3d(120%, 0, 0)",
        // opacity: 0,
      },

      panel_matte: {
        position: "fixed", top: 0, left: 0,
        zIndex: 1100,
        width: "100vw", height: "100vh",
        background: "rgba(0, 0, 0, .5)",
        transition: "opacity .5s",
      },
    };

    let panel_submodule = null;
    switch (this.props.type) {
      case "alert":
        panel_submodule = <ConfigPanelAlert symbol={this.props.symbol} dismiss={this.dismiss} animate_error={this.animate_error} />;
        break;
      case "buy":
        panel_submodule = <ConfigPanelBuy symbol={this.props.symbol} dismiss={this.dismiss} submit={this.props.submit} animate_error={this.animate_error} />;
        break;
      case "sell":
        panel_submodule = <ConfigPanelSell symbol={this.props.symbol} dismiss={this.dismiss} submit={this.props.submit} animate_error={this.animate_error} />;
        break;
      default:
        ;
    }

    return (
      <React.Fragment>
        <div className="config-panel-matte" style={style.panel_matte} ref={this.panel_matte} onClick={this.dismiss}></div>
        <div className="config-panel" style={style.panel} ref={this.panel}>
          {this.props.show ? panel_submodule : null}
        </div>
      </React.Fragment>
    );

  }
});

function state_map(state) {
  return state.config_panel;
}
