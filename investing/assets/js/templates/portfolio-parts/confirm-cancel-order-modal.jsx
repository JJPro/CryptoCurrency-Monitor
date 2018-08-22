import React from 'react';
import utils from '../../redux/utils';

export default function ConfirmCancelOrderModal(props) {
  // props : {orderToCancel: order}
  let symbol, id, action, target;
  props.orderToCancel && ({symbol, id, action, target} = props.orderToCancel);

  let style = {};
  style.symbol = {color: "dodgerblue",fontWeight: "bold",textDecoration: "underline",};


  return (
    <div className="modal fade" id="confirmCancelOrderModal" tabIndex="-1" role="dialog" aria-labelledby="exampleModalLabel" aria-hidden="true">
      <div className="modal-dialog modal-dialog-centered" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title" id="exampleModalLabel">Are You Sure?</h5>
            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div className="modal-body">
            You are about to <span className="font-weight-bold">cancel</span> <span className={(action=="buy"?"text-success":"text-danger") + " font-weight-bold font-italic"}>
              {action}
            </span> <span style={style.symbol}>
              {symbol}
            </span> at <span className="font-italic font-weight-bold">
              {target && utils.currencyFormatString(target, true)}
            </span>
            .
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" data-dismiss="modal">Abort Operation</button>
            <button type="button" className="btn btn-danger" onClick={() => props.cancelOrder(props.orderToCancel)}>Confirm Cancel</button>
          </div>
        </div>
      </div>
    </div>
  );
}
