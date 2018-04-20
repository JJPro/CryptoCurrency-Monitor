import store from './store';

class API {
  request_assets(token){
    // get request
    fetch(`/api/v1/assets/user/${token}`)
    .then( resp => resp.json() )
    .then( resp => {
      store.dispatch({
        type: "LIST_ASSETS",
        assets: resp.data,
      });
    });
  }

  lookup_asset(term, callback){
    // get request
    fetch(`/api/v1/assets/lookup/${term}`)
    .then( resp => resp.json() )
    .then( resp => {
      // console.log(resp);
      store.dispatch({
        type: "SET_PROMPTS",
        prompts: resp.data
      });
    })
    .then( () => {
      callback && callback();
    })
    .catch( error => console.log("Error:", error) );
  }

  create_asset(token, asset, callback) {
    // normal RESTFUL post to :create
    fetch(`/api/v1/assets`, {
      method: 'POST',
      body: JSON.stringify({token, asset}),
      headers: {'Content-Type': 'application/json'}
    })
    .then( resp => resp.json() )
    .then( (resp) => {
      // console.log(resp);
      store.dispatch({
        type: "ADD_ASSET",
        asset: resp.data,
      });
    } )
    .then(() => {
      callback && callback();
    })
    .catch( error => console.log("Error:", error) );
  }

  request_alerts(token){
    // get request
  }

  create_alert(token, alert, callback) {
    // normal RESTFUL post to :create

  }

  delete_asset(token, asset){
    // normal RESTFUL DELETE request
  }

  delete_alert(token, alert){
    // normal RESTFUL DELETE request
  }

}

export default new API();
