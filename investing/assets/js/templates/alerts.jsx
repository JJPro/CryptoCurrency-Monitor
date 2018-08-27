import React, { Component } from 'react';
import { connect } from 'react-redux';
import api from '../redux/api';
import store from '../redux/store';
import socket from '../socket';
import ConfirmationModal from './confirmation-modal';
import utils from '../redux/utils';

export default class Alerts extends Component {
  constructor(props) {
    super(props);

    this.state = {
      activeAlerts: [], // alert is {symbol, quote, trend}
      inactiveAlerts: [],
      alertToRemove: null,
    };

    this.channelInit();

    this.removeAlert = this.removeAlert.bind(this);
    this.setAlertToRemove = this.setAlertToRemove.bind(this);
    this.removeAlertConfirmationBody = this.removeAlertConfirmationBody.bind(this);
  }

  channelInit(){
    this.channel = socket.channel(`alert:${window.user_id}`);
    this.channel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join watchlist channel from alerts page", resp) });

    this.channel.on("init alert list", ({active, inactive}) => {
      // console.log("initializing alerts, active: ", active, ", inactive: ", inactive);
      this.setState({activeAlerts: active, inactiveAlerts: inactive});
    });

    this.channel.on("price updated", ({symbol, price}) => {
      // console.log("price updated, symbol: ", symbol, ", price: ", price);
      let updatedActiveAlerts = this.state.activeAlerts.map(a => {
        if (symbol == a.symbol){
          let trend = price > a.quote ? "up" : "down";
          return Object.assign(a, {quote: price, trend: trend});
        }
        else return a;
      });
      this.setState({activeAlerts: updatedActiveAlerts});
    });

    /** The following three messages are sent from AlertManager
     * - "alert created",
     * - "alert deleted",
     * - "alert expired"
     */
    this.channel.on("alert created", ({alert}) => {
      let updatedActiveAlerts = Array.from(this.state.activeAlerts);
      updatedActiveAlerts.unshift(Object.assign(alert, {trend: null}));
      this.setState({activeAlerts: updatedActiveAlerts});
    });

    this.channel.on("alert deleted", ({alert}) => {
      // remove alert from according state list
      console.log("alert deleted, alert:", alert);
      if (alert.expired){
        let index = this.state.inactiveAlerts.findIndex( a => a.id == alert.id);
        this.state.inactiveAlerts.splice(index, 1);
        this.setState({
          inactiveAlerts: this.state.inactiveAlerts
        });
      } else {
        let index = this.state.activeAlerts.findIndex( a => a.id == alert.id);
        this.state.activeAlerts.splice(index, 1);
        this.setState({
          activeAlerts: this.state.activeAlerts
        });
      }
    });

    this.channel.on("alert expired", ({alert}) => {
      // remove from activeAlerts,
      let activeAlerts = this.state.activeAlerts.filter(a => a.id != alert.id);

      // unshift to inactiveAlerts.
      let inactive = this.state.inactiveAlerts;
      alert.expired = true;
      inactive.unshift(alert);

      this.setState({activeAlerts: activeAlerts, inactiveAlerts: inactive});
    });

  }

  setAlertToRemove(alert){
    this.setState({alertToRemove: alert});
  }

  removeAlert() {
    let alert = this.state.alertToRemove;

    console.log("pushing \"delete alert\", alert: ", alert);
    this.channel.push("delete alert", {alert_id: alert.id})
    .receive("ok", () => utils.dismissModal("#confirmationModal"))
    .receive("error", () => utils.reportError("An error occurred, please try again later."));
  }

  removeAlertConfirmationBody(){
    let style={
      symbol: {color: "dodgerblue",fontWeight: "bold",textDecoration: "underline",},
      condition: {color: "orange", fontWeight: "bold"},
    };
    let symbol, condition, expired;
    this.state.alertToRemove && ({symbol, condition, expired} = this.state.alertToRemove);

    if (expired){
      return (
        <React.Fragment>
          You are about to delete this alert entry from your alerts history.
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          You are about to delete alert <span style={style.symbol}>{symbol}</span> <span style={style.condition}>{condition}</span>
        <small className="form-text text-muted">You will not get notifications about it any more.</small>
        </React.Fragment>
      );
    }
  }

  render() {

    let style = {};

    return (
      <div>
        <div>
          <h2>Active Alerts</h2>
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
                this.state.activeAlerts.map(
                  (alert) => <AlertEntry alert={ alert } setAlertToRemove={ this.setAlertToRemove } key={ alert.id } /> )
              }
            </tbody>
          </table>

        </div>
        <div>
          <h2>Expired Alerts</h2>
          <table className="table">
            <thead>
              <tr>
                <th>Symbol</th>
                <th>Condition</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {
                this.state.inactiveAlerts.map(
                  (alert) => <AlertEntry alert={ alert } setAlertToRemove={ this.setAlertToRemove } key={ alert.id } /> )
              }
            </tbody>
          </table>

        </div>
        <ConfirmationModal body={this.removeAlertConfirmationBody()} abortText="Keep" confirmButtonClass="btn-danger" confirmText="Confirm Delete"
          confirmAction={this.removeAlert} />
      </div>
    );
  }
}

/*** ================================ ***/

function AlertEntry(props) {

  let style = {};
  style.symbol = {color: "dodgerblue", fontWeight: "bold"};
  style.price  = {
    fontWeight: "bold",
  };
  switch (props.alert.trend) {
    case "up":
      style.price.color = "#28a745";
      break;
    case "down":
      style.price.color = "#dc3545";
      break;
    default:
      style.price.color = "inherit";
  }
  style.close_btn = {borderRadius: "50%", padding: "2px", fontSize: "1.5rem", fontWeight: 700, lineHeight: 1, color: "#000", textShadow: "0 1px 0 #fff", opacity: .5, width: "1.5em", height: "1.5em", marginRight: "15px",};
  style.close_txt = {verticalAlign: "text-top"};

  return (
    <tr>
      <td style={style.symbol}>{ props.alert.symbol }</td>
      {!props.alert.expired && <td style={style.price }>{ props.alert.quote }</td>}
      <td style={style.condition}>{ props.alert.condition }</td>
      <td style={style.actioncell}>
        <button type="button" style={style.close_btn} aria-label="Close" onClick={ () => props.setAlertToRemove(props.alert) } data-toggle="modal" data-target="#confirmationModal" >
          <span aria-hidden="true" style={style.close_txt}>&times;</span>
        </button>
      </td>
    </tr>
  );
}
