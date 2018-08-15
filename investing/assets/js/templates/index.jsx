import React from 'react';
import { render } from 'react-dom';
import { BrowserRouter as Router, Route, Switch, NavLink } from 'react-router-dom';
import { Provider, connect } from 'react-redux';
import store from '../redux/store';
import api from '../redux/api';

import ActionPanel from './action-panel';
import ConfigPanel from './config-panel';
import Watchlist from './watchlist';
import Alerts from './alerts';
import Portfolio from './portfolio';

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

  window.store = store; // DEBUG for debugging purposes
  let style = {};

  return (
    <Router>
      <div>
        <div className="my-3">
          <NavLink to="/" exact >Watchlist </NavLink>
          |
          <NavLink to="/alerts" exact > Alerts </NavLink>
          |
          <NavLink to="/portfolio" exact > Portfolio</NavLink>
        </div>
        <Switch>
          <Route path="/" exact component={Watchlist} />}
          <Route path="/alerts" exact component={Alerts} />
          <Route path="/portfolio" exact component={Portfolio} />
        </Switch>
        <ActionPanel />
        <ConfigPanel />
      </div>
    </Router>
  );
});
