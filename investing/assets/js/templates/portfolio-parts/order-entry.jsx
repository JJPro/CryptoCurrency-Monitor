import React from 'react';

export default function OrderEntry(props) {
  let style = {
    close_btn: {borderRadius: "50%", padding: "2px", fontSize: "1.5rem", fontWeight: 700, lineHeight: 0.5, color: "#000", textShadow: "0 1px 0 #fff", opacity: .5, width: "1.5em", height: "1.5em", marginRight: "15px",},

  };

  function confirmCancelOrder(order){
    // pop up to confirm cancellation
    props.setOrderToCancel(order);
  }

  return (
    <tr>
      <th scope="row">{props.order.symbol}</th>
      <td>{props.order.action}</td>
      <td>{utils.currencyFormatString(props.order.target)}</td>
      <td>{props.order.quantity}</td>
      <td>{props.order.stoploss && utils.currencyFormatString(props.order.stoploss)}</td>
      <td>{props.order.status}</td>
      <td>
        {
          props.order.status == "pending" &&
          <button type="button" style={style.close_btn} aria-label="Close" onClick={ () => confirmCancelOrder(props.order) } data-toggle="modal" data-target="#confirmCancelOrderModal">
            <svg fill="#000000" height="24" viewBox="0 0 24 24" width="24" xmlns="http://www.w3.org/2000/svg">
                <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/>
                <path d="M0 0h24v24H0z" fill="none"/>
            </svg>
          </button>
      }
      </td>
    </tr>
  )
}
