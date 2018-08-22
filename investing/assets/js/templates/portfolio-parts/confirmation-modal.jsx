import React from 'react';
import utils from '../../redux/utils';

export default function ConfirmModal(props) {
  /**
   * props: {
   *    title - optional, default: "Are You Sure?"
   *    body
   *    abortText - optional, default: "Abort Operation"
   *    confirmButtonClass - optional, no default value.
   *    confirmText - optional, default: "Confirm"
   *    confirmAction
   * }
   */

  return (
    <div className="modal fade" id="confirmationModal" tabIndex="-1" role="dialog" aria-labelledby="confirmationModalLabel" aria-hidden="true">
      <div className="modal-dialog modal-dialog-centered" role="document">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title" id="confirmationModalLabel">
              {props.title && "Are You Sure?"}
            </h5>
            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
          </div>
          <div className="modal-body">
            {props.body}
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" data-dismiss="modal">
              { props.abortText && "Abort Operation"}
            </button>
            <button type="button" className="btn {props.confirmButtonClass}" onClick={() => props.confirmAction()}>
              { props.confirmText && "Confirm" }
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
