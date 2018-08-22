import React, { Component } from 'react';
import { connect } from 'react-redux';
import socket from '../socket';
import api from '../redux/api';
import store from '../redux/store';
import utils from '../redux/utils';

import OrderEntry from './portfolio-parts/order-entry';
import HoldingEntry from './portfolio-parts/holding-entry';
import ConfirmationModal from './confirmation-modal';


export default connect( state_map )( class Portfolio extends Component {
  constructor(props){
    super(props);
    this.state = {
      liveQuotes: [],
      orders: {
        active: [],
        inactive: []
      },
      orderToCancel: null,
    };

    window.utils = utils;
    window.portfolio = this;

    this.channelInit();

    this.cancelOrder = this.cancelOrder.bind(this);
    this.confirmationModalBody = this.confirmationModalBody.bind(this);
  }

  channelInit() {
    /* ========== Join =========== */
    this.holdingsChannel = socket.channel(`holdings:${window.user_id}`);
    this.holdingsChannel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join holdings channel", resp) });

    this.ordersChannel = socket.channel(`orders:${window.user_id}`);
    this.ordersChannel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join orders channel", resp) });

    this.holdingsChannelMessagesSetup();
    this.ordersChannelMessagesSetup();

  }

  holdingsChannelMessagesSetup(){
    // this.holdingsChannel.on("test", (data) => console.log(data));
    this.holdingsChannel.on("price updated", ({symbol, price}) => {
      /**
      * update quote if already present in state
      * otherwise add to state
      */
      // console.log(this.state.liveQuotes);
      if (this.state.liveQuotes.some(q => q.symbol == symbol)) {
        this.setState({
          liveQuotes: this.state.liveQuotes.map(q => {
            if (q.symbol == symbol){
              let trend = price > q.quote ? "up" : "down";
              // console.log("trend", trend);
              return {symbol: symbol, quote: price, trend: trend};
            }
            else
            return q;
          })
        });
      } else {
        let newQuotes = Array.from(this.state.liveQuotes);
        newQuotes.push({symbol: symbol, quote: price, trend: null});
        // console.log("new quotes", newQuotes);
        this.setState({
          liveQuotes: newQuotes,
        });
      }
    });

  }

  ordersChannelMessagesSetup(){
    this.ordersChannel.on("init order list", ({active, inactive}) => {
      this.setState({orders: {active: active, inactive: inactive}});
    });
    this.ordersChannel.on("order_canceled", ({order}) => {
      this.moveOrderToInactive(order);
    });
    this.ordersChannel.on("order_placed", ({order}) => {
      let new_active = this.state.orders.active;
      new_active.unshift(order);
      this.setState({
        orders: {
          active: new_active,
          inactive: this.state.orders.inactive
        }
      });
    });
    this.ordersChannel.on("order_executed", ({order}) => {
      this.moveOrderToInactive(order);
    });
  }

  cancelOrder(){
    this.ordersChannel.push("cancel order", {order_id: this.state.orderToCancel.id})
    .receive("ok", () => utils.dismissModal("#confirmationModal"))
    .receive("error", () => utils.reportError("an error has occurred, please try again later."));
  }

  moveOrderToInactive(order) {
    // remove from active list
    let active = this.state.orders.active.filter( o => o.id != order.id );

    // add to head of inactive list
    let inactive = Array.from(this.state.orders.inactive);
    inactive.unshift(order);
    this.setState( {orders: {active: active, inactive: inactive}} );
  }

  quote(symbol){
    let quoteObject = this.state.liveQuotes.find( q => q.symbol == symbol );
    return quoteObject;
  }

  confirmationModalBody(){
    let symbol, id, action, target;
    this.state.orderToCancel && ({action, symbol, target} = this.state.orderToCancel);
    let style = {};
    style.symbol = {color: "dodgerblue",fontWeight: "bold",textDecoration: "underline",};

    return (
      <React.Fragment>
        You are about to <span className="font-weight-bold">cancel</span> <span className={(action=="buy"?"text-success":"text-danger") + " font-weight-bold font-italic"}>
          {action}
        </span> <span style={style.symbol}>
          {symbol}
        </span> at <span className="font-italic font-weight-bold">
          {target && utils.currencyFormatString(target, true)}
        </span>
        .
      </React.Fragment>
    );
  }

  render(){
    let style = {
      summary: {
        label: {display: "inline-block", width: "9em", fontWeight: "bold"},
        value: {fontWeight: 500},
      },
    };
    let totalGainColor;

    let totalEquityStr; // "balance + sum(value of holdings)"
    let totalGainStr; // e.g. "+$1,100.99"
    let totalGainPercentStr; // "10.12%"

    if (this.state.liveQuotes.length == new Set(this.props.holdings.map( h => h.symbol )).size){
      // all live quotes are ready, let's calculate the total equity and total gain
      let holdingSum = this.props.holdings.reduce( (acc, h) => acc + this.quote(h.symbol).quote, 0);
      let totalEquity = this.props.balance.total + holdingSum;
      totalEquityStr = utils.currencyFormatString(totalEquity, true);

      let totalGain = this.props.holdings.reduce( (acc, h) => acc + h.quantity * (this.quote(h.symbol).quote - h.bought_at), 0);
      totalGainStr = utils.currencyFormatString(totalGain, true, true);

      totalGainColor = totalGain >= 0 ? "#28a745" : "#dc3545";

      totalGainPercentStr = utils.percentFormatString( totalGain / (holdingSum - totalGain) );
      totalGainPercentStr = `(${totalGainPercentStr})`;
    } else {
      // otherwise, let's represent total equity with '...'
      totalEquityStr = "...";
      totalGainStr = totalGainPercentStr = "";
    }

    // console.log("rendering orders", this.state.orders);
    return (
      <div id="portfolio">
        <h1>Portfolio</h1>
        <div className="row account-summary shadow-sm p-2">
          <div className="col-auto mr-3">
            <span style={style.summary.label}>Total Equity:</span> <span style={style.summary.value}>{ totalEquityStr }</span>
            <br/>
            <span style={style.summary.label}>Purchase Power:</span> <span  style={style.summary.value}>{utils.currencyFormatString(this.props.balance.usable, true)}</span>
          </div>
          <div className="col">
            <span style={{...style.summary.label, width:"6em"}}>Total Gain:</span> <span style={{...style.summary.value, color: totalGainColor}}>{`${totalGainStr}${totalGainPercentStr}`}</span>
          </div>
        </div>
        <div className="position" style={style.position}>
          <h2>Position:</h2>
          <table className="table">
            <thead className="thead-light">
              <tr>
                <th scope="col">Symbol</th>
                <th scope="col">Bought at</th>
                <th scope="col">Price</th>
                <th scope="col">Qty</th>
                <th scope="col">Gain/Loss</th>
                <th scope="col"></th>
              </tr>
            </thead>
            <tbody>
              {this.props.holdings.map( h => <HoldingEntry holding={h} quote={this.quote(h.symbol)} key={h.id} /> )}
            </tbody>
          </table>
        </div>
        <div className="orders" style={style.orders}>
          <h2>Order History:</h2>
          <table className="table">
            <thead className="thead-light">
              <tr>
                <th scope="col">Symbol</th>
                <th scope="col">Action</th>
                <th scope="col">Target Price</th>
                <th scope="col">Quantity</th>
                <th scope="col">Stop loss</th>
                <th scope="col">Status</th>
                <th scope="col"></th>
              </tr>
            </thead>
            <tbody>
              {this.state.orders.active.map( o => <OrderEntry order={o} key={o.id} setOrderToCancel={ order => {this.setState({orderToCancel: order})} } />)}
              {this.state.orders.inactive.map( o => <OrderEntry order={o} key={o.id} />)}
            </tbody>
          </table>
          <ConfirmationModal body={this.confirmationModalBody()} confirmButtonClass="btn-danger" confirmText="Confirm Deletion" confirmAction={ this.cancelOrder }/>
        </div>
      </div>
    );
  }
});

function state_map(state) {
  return {
    balance: state.balance,
    holdings: state.holdings,
    // orders: state.orders,
  };
}
