export default (state = default_balance, action) => {
  switch (action.type) {
    case "SET_BALANCE":
      // console.log("setting balance", "old", state, "new", action.balance);
      return Object.assign({}, state, action.balance);
    default:
      return state;
  }
}

const default_balance = {
  total: "loading...",
  usable: "loading...",
};
