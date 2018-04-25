import store from './store';

class API {
  request_assets(token, callback){
    // get request
    fetch(`/api/v1/assets/user/${token}`)
    .then( resp => resp.json() )
    .then( resp => {
      store.dispatch({
        type: "LIST_ASSETS",
        assets: resp.data,
      });
    })
    .then( () => callback && callback() );
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

  add_asset(token, symbol, callback) {
    // console.log("token", token);
    // normal RESTFUL post to :create
    fetch(`/api/v1/assets`, {
      method: 'POST',
      body: JSON.stringify({token, symbol}),
      headers: {'Content-Type': 'application/json'}
    })
    .then( resp => resp.json() )
    .then( resp => {
      if (resp.data) {
        store.dispatch({
          type: "ADD_ASSET",
          asset: resp.data,
        });
        callback && callback();
      } else {
        // errors
      }
    })
    .catch( error => console.log("Error:", error) );
  }

  delete_asset(token, asset){
    // normal RESTFUL DELETE request
    fetch(`/api/v1/assets/${asset.id}`, {
      method: 'DELETE',
      body: JSON.stringify({token}),
      headers: {'Content-Type': 'application/json'}
    })
    .then( (resp) => {
      store.dispatch({
        type: "DELETE_ASSET",
        asset_id: asset.id,
      });
    })
    .catch( error => console.log("Error:", error) );
  }

  request_alerts(token, callback){
    // get request
    fetch(`/api/v1/alerts/user/${token}`)
    .then( resp => {
      // console.log(">>>>> alerts", resp)
      return resp.json()
    } )
    .then( resp => {
      store.dispatch({
        type: "LIST_ALERTS",
        alerts: resp.data,
      });
    })
    .then( () => callback && callback() );
  }

  add_alert(token, symbol, condition, callback) {
    // normal RESTFUL post to :create
    fetch(`/api/v1/alerts`, {
      method: 'POST',
      body: JSON.stringify({token, symbol, condition}),
      headers: {'Content-Type': 'application/json'}
    })
    .then( resp => resp.json() )
    .then( resp => {
      if (resp.data) {
        store.dispatch({
          type: "ADD_ALERT",
          alert: resp.data,
        });
        callback && callback();
      } else {
        // errors
      }
    })
    .catch( error => console.log("Error:", error) );
  }

  delete_alert(token, alert, callback){
    // normal RESTFUL DELETE request
    fetch(`/api/v1/alerts/${alert.id}`, {
      method: 'DELETE',
      body: JSON.stringify({token}),
      headers: {'Content-Type': 'application/json'}
    })
    .then( (resp) => {
      store.dispatch({
        type: "DELETE_ALERT",
        alert_id: alert.id,
      });
      callback && callback();
    })
    .catch( error => console.log("Error:", error) );
  }

}

export default new API();
