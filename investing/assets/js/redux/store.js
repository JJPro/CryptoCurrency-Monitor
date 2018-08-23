import { createStore, combineReducers } from 'redux';
import currentAssetReducer from './reducers/reducer-current-asset';
import assetsReducer from './reducers/reducer-assets';
import configPanelReducer from './reducers/reducer-config-panel';
import balanceReducer from './reducers/reducer-balance';
import holdingsReducer from './reducers/reducer-holdings';
// import ordersReducer from './reducers/reducer-orders';


export default createStore(
  combineReducers({
    current_asset: currentAssetReducer,
    assets: assetsReducer,
    config_panel: configPanelReducer,
    balance: balanceReducer,
    holdings: holdingsReducer,
    // orders: ordersReducer,
  })
);
