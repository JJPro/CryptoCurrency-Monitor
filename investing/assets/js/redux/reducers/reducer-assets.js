export default (state = [], action) => {
  switch (action.type) {
    case "ADD_ASSET":
      return Object.assign([], state, [action.asset]);
    case "LIST_ASSETS":
      return action.assets;
    default:
      return state;
  }
}
