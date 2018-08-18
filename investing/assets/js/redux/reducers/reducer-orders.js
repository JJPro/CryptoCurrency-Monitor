export default (state = _default, action) => {
  switch (action.type) {
    case "INIT_ORDERS":
      return action.orders;

    case "ADD_ORDER":
      if (action.order.status == "pending")
      {
        let active = Array.from(state.active);
        active.unshift(action.order);
        return Object.assign({}, state, {active: active});
      } else {
        let inactive = Array.from(state.inactive);
        inactive.unshift(action.order);
        return Object.assign({}, state, {inactive: inactive});
      }

    /** pending -> executed/canceled,
     *  simply remove from active list to head of inactive list
    **/
    case "UPDATE_ORDER_STATUS":
      // remove from active list
      let active = state.active.filter( o => o.id != action.order.id );

      // add to head of inactive list
      let inactive = Array.from(state.inactive);
      inactive.unshift(action.order);
      return {active: active, inactive: inactive};

    default:
      return state;
  }
}

const _default = {
  active: [],
  inactive: [],
};
