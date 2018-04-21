export default (state = [], action) => {
  switch (action.type) {
    case "LIST_ASSETS":
      return action.assets.map( (a) => Object.assign({}, base_asset_obj, a) );
    case "ADD_ASSET":
      return [...state, Object.assign({}, base_asset_obj, action.asset)];
    case "UPDATE_ASSET_PRICE":
      return state.map(
        (a) => {
          if (a.symbol == action.asset.symbol){
            let price_color = a.price < action.asset.price ? "limegreen" : "red";
            let price = Math.round(action.asset.price * 100, 2) / 100;
            return Object.assign({}, a, {price, price_color});
          } else {
            return a;
          }
        }
      );
    case "DELETE_ASSET":
      return state.filter( a => a.id != action.asset_id );
    default:
      return state;
  }
}

let base_asset_obj = {
  symbol: "",
  id: null,
  price: "--",
  price_color: "black",
}
