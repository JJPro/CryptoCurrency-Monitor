import store from './store';

class API {
  request_assets(token){
    // get request
    fetch('/api/v1/assets')
    .then()
  }

  request_alerts(token){
    // get request
  }

  lookup_asset(term, callback){
    // get request

  }

  create_asset(token, asset, callback) {
    // normal RESTFUL post to :create
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
