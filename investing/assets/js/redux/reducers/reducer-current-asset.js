export default (state = no_asset, action) => {
  switch (action.type) {

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
