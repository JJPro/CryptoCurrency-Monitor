export default (state = [], action) => {
  switch (action.type) {
    case "LIST_ALERTS":
      return action.alerts.map( (a) => Object.assign({}, base_alert_obj, a) );
    case "ADD_ALERT":
      return [...state, Object.assign({}, base_alert_obj, action.alert)];
    case "UPDATE_ALERT_PRICE": // make use of the assets channel
      return state.map(
        (a) => {
          if (a.symbol == action.alert.symbol){
            let price_color = a.price < action.alert.price ? "limegreen" : "red";
            let price = Math.round(action.alert.price * 100, 2) / 100;
            return Object.assign({}, a, {price, price_color});
          } else {
            return a;
          }
        }
      );
    case "DELETE_ALERT":
      return state.filter( a => a.id != action.alert_id );
    default:
      return state;
  }
}

let base_alert_obj = {
  id: null,
  symbol: "",
  price: "--",
  price_color: "black",
  condition: "",
  expired: false,
}
