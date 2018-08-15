export default (state = no_config_options, action) => {
  switch (action.type) {
    case "CONFIG_ASSET":
      return Object.assign({}, no_config_options, action.config_options);
    case "CLEAR_CONFIG":
      return Object.assign({}, state, {show: false});
    default:
      return state;
  }
}

let no_config_options = {
  show: true,
  symbol: "",
  type: "", // "alert" or "buy" or "sell"
  submit: null, 
}
