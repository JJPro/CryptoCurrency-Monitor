import React, { Component } from 'react';
import { connect } from 'react-redux';
import socket from '../socket';
import api from '../redux/api';
import store from '../redux/store';
import utils from '../redux/utils';


export default connect( state_map )( class Portfolio extends Component {
  constructor(props){
    super(props);
    this.state = {
      liveQuotes: []
    };

    window.utils = utils;

    this.channelInit();
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
            if (q.symbol == symbol)
            return {symbol: symbol, quote: price};
            else
            return q;
          })
        });
      } else {
        let newQuotes = Array.from(this.state.liveQuotes);
        newQuotes.push({symbol: symbol, quote: price});
        // console.log("new quotes", newQuotes);
        this.setState({
          liveQuotes: newQuotes,
        });
      }
    });

  }

  ordersChannelMessagesSetup(){

  }

  quote(symbol){
    let quoteObject = this.state.liveQuotes.find( q => q.symbol == symbol );
    return quoteObject && quoteObject.quote;
  }

  render(){
    let style = {};

    let totalEquityStr; // "balance + sum(value of holdings)"
    let totalGainStr; // e.g. "+$1,100.99"
    let totalGainPercentStr; // "10.12%"

    if (this.state.liveQuotes.length == new Set(this.props.holdings.map( h => h.symbol )).size){
      // all live quotes are ready, let's calculate the total equity and total gain
      let holdingSum = this.props.holdings.reduce( (acc, h) => acc + this.quote(h.symbol), 0);
      let totalEquity = this.props.balance.total + holdingSum;
      totalEquityStr = utils.currencyFormatString(totalEquity, true);

      let totalGain = this.props.holdings.reduce( (acc, h) => acc + h.quantity * (this.quote(h.symbol) - h.bought_at), 0);
      totalGainStr = utils.currencyFormatString(totalGain, true);

      totalGainPercentStr = utils.percentFormatString( totalGain / (holdingSum - totalGain) );
      totalGainPercentStr = `(${totalGainPercentStr})`;
    } else {
      // otherwise, let's represent total equity with '...'
      totalEquityStr = "...";
      totalGainStr = totalGainPercentStr = "";
    }


    return (
      <div id="portfolio">
        <h1>Portfolio</h1>
        <ul className="account-summary" style={style.summary}>
          <li>Total Equity: { totalEquityStr }</li>
          <li>Purchase Power: {utils.currencyFormatString(this.props.balance.usable, true)}</li>
          <li>Total Gain: <span style={style.totalGain}>{`${totalGainStr}${totalGainPercentStr}`}</span></li>
        </ul>
        <h2>Position:</h2>
        <table className="table">
          <thead className="thead-light">
            <tr>
              <th scope="col">Symbol</th>
              <th scope="col">Bought at</th>
              <th scope="col">Price</th>
              <th scope="col">Qty</th>
              <th scope="col">Gain/Loss</th>
            </tr>
          </thead>
          <tbody>
            {this.props.holdings.map( h => <HoldingEntry holding={h} quote={this.quote(h.symbol)} key={h.id} /> )}
          </tbody>
        </table>
      </div>
    );
  }



});

function state_map(state) {
  return {
    balance: state.balance,
    holdings: state.holdings,

  };
}

function HoldingEntry(props){
  let quoteStr, gainStr;
  quoteStr = gainStr = "";
  if (props.quote){
    quoteStr = utils.currencyFormatString(props.quote, true);
    let gain = props.quote - props.holding.bought_at;
    let gainDollarStr = utils.currencyFormatString(gain, true);
    let gainPercentStr = utils.percentFormatString(gain/props.holding.bought_at);
    gainStr = `${gainDollarStr} (${gainPercentStr})`;
  }

  return (
    <tr>
      <th scope="row">{props.holding.symbol}</th>
      <td>{props.holding.bought_at}</td>
      <td>{quoteStr}</td>
      <td>{props.holding.quantity}</td>
      <td>{gainStr}</td>
    </tr>
  );
}
