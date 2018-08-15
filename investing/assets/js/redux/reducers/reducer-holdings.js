export default (state = _default, action) => {
  switch (action.type) {
    case "INIT_HOLDINGS":
      return action.holdings;
    case "INCREASE_HOLDING": // triggers on buy order execution
      if (state.some((holding) => _holdings_match(holding, action.holding))){
        return state.map( holding => {
          if (_holdings_match(holding, action.holding))
            return Object.assign({}, holding, {quantity: holding.quantity + action.holding.quantity});
          else
            return holding;
        });
      } else return Array.from(state).unshift(action.holding);


    case "DECREASE_HOLDING": // triggers on sell execution, resulting entry decrease
      return state.map((holding) => {
        if (_holdings_match(holding, action.holding))
          return Object.assign({}, holding, {quantity: holding.quantity - action.amt});
        else return holding;
      });


    case "DELETE_HOLDING": // triggers on sell execution, resulting entry deletion
      let target_holding = state.find( h => _holdings_match(h, action.holding) );
      if ( target_holding.quantity > action.holding.quantity ){
        return state.map( h => {
          if (h == target_holding)
            return Object.assign({}, h, {quantity: h.quantity - action.holding.quantity});
          else return h;
        });
      } else {
        return state.filter( h => h != target_holding );
      }


    default:
      return state;
  }
}

const _default = [];

function _holdings_match(h1, h2){
  return h1.symbol == h2.symbol && h1.bought_at == h2.bought_at;
}
