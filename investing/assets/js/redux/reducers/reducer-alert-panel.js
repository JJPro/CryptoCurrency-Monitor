export default (state = no_alert, action) => {
  switch (action.type) {
    case "SET_ALERT":
      return Object.assign({}, no_alert, action.alert);
    case "CLEAR_ALERT":
      return no_alert;
    default:
      return state;
  }
}

let no_alert = {
  symbol: "",
  threshold: "",
  condition: ">",
}
