import React from 'react';

export default function HoldingEntry(props){
  let quoteStr, gainStr;
  quoteStr = gainStr = "";
  if (props.quote){
    quoteStr = utils.currencyFormatString(props.quote, true);
    let gain = props.quote - props.holding.bought_at;
    let gainDollarStr = utils.currencyFormatString(gain, true);
    let gainPercentStr = utils.percentFormatString(gain/props.holding.bought_at);
    gainStr = `${gainDollarStr} (${gainPercentStr})`;
  }

  let style = {
    sell_btn: {
      width: "55px", lineHeight: 2, borderRadius: "20px", fontSize: "1rem", fontWeight:700, color: "#fff", opacity: .9, marginRight: "15px"
    },
  };

  return (
    <tr>
      <th scope="row">{props.holding.symbol}</th>
      <td>{props.holding.bought_at}</td>
      <td>{quoteStr}</td>
      <td>{props.holding.quantity}</td>
      <td>{gainStr}</td>
      <td><button className="bg-danger" style={style.sell_btn} onClick={() => utils.configSell(props.holding.symbol)}>Sell</button></td>
    </tr>
  );
}
