/**
 * Created by artald on 15/05/2016.
 */

import React, {PureComponent} from 'react';
import ReactNative, {requireNativeComponent, NativeModules} from 'react-native';

const NativeKeyboardTrackingView = requireNativeComponent('KeyboardTrackingView', null);
const KeyboardTrackingViewManager = NativeModules.KeyboardTrackingViewManager;

export default class KeyboardTrackingView extends PureComponent {
  constructor(props) {
    super(props);
  }
  render() {
    return (
      <NativeKeyboardTrackingView {...this.props} ref={r => this.ref = r}/>
    );
  }

  getNativeProps(callback) {
    if (this.ref && KeyboardTrackingViewManager && KeyboardTrackingViewManager.getNativeProps) {
      KeyboardTrackingViewManager.getNativeProps(ReactNative.findNodeHandle(this.ref), callback);
    } else {
      callback({});
    }
  }

  scrollToStart() {
    if (this.ref && KeyboardTrackingViewManager && KeyboardTrackingViewManager.scrollToStart) {
      KeyboardTrackingViewManager.scrollToStart(ReactNative.findNodeHandle(this.ref));
    }
  }
}
