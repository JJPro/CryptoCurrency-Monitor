import React from 'react';

export default function HoldingEntry(props){
  let quoteStr, gainStr;
  let gainStrColor, quoteColor;
  quoteStr = gainStr = "";
  if (props.quote){
    quoteStr = utils.currencyFormatString(props.quote.quote, true);
    let gain = props.quote.quote - props.holding.bought_at;
    let gainDollarStr = utils.currencyFormatString(gain, true, true);
    let gainPercentStr = utils.percentFormatString(gain/props.holding.bought_at);
    gainStr = `${gainDollarStr} (${gainPercentStr})`;
    gainStrColor = (gain >= 0) ? "#28a745": "#dc3545";

    // console.log("quote", props.quote);
    switch (props.quote.trend) {
      case "up":
        quoteColor = "#28a745";
        break;
      case "down":
        quoteColor = "#dc3545";
        break;
    }
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
      <td style={{color: quoteColor}}>{quoteStr}</td>
      <td>{props.holding.quantity}</td>
      <td style={{color: gainStrColor}}>{gainStr}</td>
      <td><button className="bg-danger" style={style.sell_btn} onClick={() => utils.configSell(props.holding.symbol)}>Sell</button></td>
    </tr>
  );
}
