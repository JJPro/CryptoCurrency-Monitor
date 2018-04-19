import React from 'react';
import { render } from 'react-dom';
import { BrowserRouter as Router, Route, Switch, NavLink } from 'react-router-dom';
import { Provider, connect } from 'react-redux';
import store from '../redux/store';
// import api from '../redux/api';

import ActionPanel from './action-panel';
import Watchlist from './watchlist';
import Alerts from './alerts';
// import AlertPanel from './alert-panel';

import socket from '../socket';


export default (root) => {
  render(
    <Provider store={store} >
      <Index />
    </Provider>,
    root
  );
};


let Index = connect(state => state)( props => {

  window.store = store; // TODO for debugging purposes
  return (
    <Router>
      <div>
        <NavLink to="/" exact={true} >Watchlist </NavLink>
          |
        <NavLink to="/alerts" exact={true} > Alerts</NavLink>
        <Switch>
          <Route path="/" exact={true} render={
              (props) =>
              <Watchlist {...props} channel={socket.channel(`watchlist:${window.userToken}`)} />
            }
          />}
          <Route path="/alerts" exact={true} component={Alerts} />
        </Switch>
        <ActionPanel />
      </div>
    </Router>
  );
});
