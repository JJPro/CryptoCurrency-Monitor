export default (state = no_asset, action) => {
  switch (action.type) {
    case "SET_PROMPTS":
      return Object.assign({}, state, {prompts: action.prompts});
    case "CLEAR_PROMPTS":
      return Object.assign({}, state, {prompts: []});
    case "SET_CURRENT_ASSET":
      return action.asset;
    default:
      return state;
  }
}

let no_asset = {
  symbol: "",
  prompts: [],
  price: 0,
  price_color: "black",
}
