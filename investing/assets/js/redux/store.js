import { createStore, combineReducers } from 'redux';
import currentAssetReducer from './reducers/reducer-current-asset';
import assetsReducer from './reducers/reducer-assets';
import alertsReducer from './reducers/reducer-alerts';
import alertPanelReducer from './reducers/reducer-alert-panel';

export default createStore(
  combineReducers({
    current_asset: currentAssetReducer,
    assets: assetsReducer,
    alerts: alertsReducer,
    alert_panel: alertPanelReducer,
  })
);
