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

    this.channelInit();
  }

  channelInit() {
    /* ========== Join =========== */
    this.holdingChannel = socket.channel(`holdings:${window.user_id}`);
    this.holdingChannel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join holdings channel", resp) });

    this.orderChannel = socket.channel(`orders:${window.user_id}`);
    this.orderChannel.join()
    .receive("ok")
    .receive("error", resp => { console.log("Unable to join orders channel", resp) });

    /* =========== Message Handling =========== */
    this.holdingChannel.on("price updated", ({symbol, quote}) => {
      console.log(this.state.liveQuotes);
      if (this.state.liveQuotes.some(q => q.symbol == symbol)) {
        this.setState({
          liveQuotes: this.state.liveQuotes.map(q => {
            if (q.symbol == symbol)
            return {symbol: symbol, quote: quote};
            else
            return q;
          })
        });
      } else {
        let newQuotes = Array.from(this.state.liveQuotes);
        newQuotes.push({symbol: symbol, quote: quote});
        console.log("new quotes", newQuotes);
        this.setState({
          liveQuotes: newQuotes,
        });
      }
    });
  }

  render(){
    console.log("rendering");

    let style = {};

    let totalEquity = this.props.balance.total + 0; // TODO + sum(value of holdings)
    let totalGain = 0; // TODO e.g. "+$1,100.99(10%)"

    return (
      <div id="portfolio">
        <h1>Portfolio</h1>
        <ul className="account-summary" style={style.summary}>
          <li>Total Equity: {utils.currencyFormatString(totalEquity, true)}</li>
          <li>Purchase Power: {utils.currencyFormatString(this.props.balance.usable, true)}</li>
          <li>Total Gain: <span style={style.totalGain}>{totalGain}</span></li>
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
            {this.props.holdings.map( h => <HoldingEntry holding={h} key={h.id} /> )}
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
  let gain = 0; // TODO calculate gain from props.price and props.holding.bought_at
  return (
    <tr>
      <th scope="row">{props.holding.symbol}</th>
      <td>{props.holding.bought_at}</td>
      <td>{props.price}</td>
      <td>{props.holding.quantity}</td>
      <td>{gain}</td>
    </tr>
  );
}
