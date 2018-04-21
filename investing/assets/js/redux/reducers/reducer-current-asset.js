export default (state = no_asset, action) => {
  switch (action.type) {
    case "SET_CURRENT_ASSET":
      return Object.assign({}, no_asset, action.asset);
    case "SET_PROMPTS":
      return Object.assign({}, state, {prompts: action.prompts});
    case "CLEAR_PROMPTS":
      return Object.assign({}, state, {prompts: []});
    case "UPDATE_CURRENT_ASSET_PRICE":
      let color = state.price < action.asset.price ? "limegreen" : "red";
      let price = Math.round(action.asset.price * 100, 2) / 100;
      return Object.assign({}, state, {symbol: action.asset.symbol, price: price, price_color: color, prompts: []});
    default:
      return state;
  }
}

let no_asset = {
  symbol: "",
  name: "",
  market: "",
  prompts: [],
  price: "--",
  price_color: "black",
}
