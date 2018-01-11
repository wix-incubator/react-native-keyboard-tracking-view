/**
 * Created by artald on 15/05/2016.
 */

import React, {PureComponent} from 'react';
import {requireNativeComponent} from 'react-native';

const NativeKeyboardTrackingView = requireNativeComponent('KeyboardTrackingView', null);

export default class KeyboardTrackingView extends PureComponent {
  constructor(props) {
    super(props);
  }
  render() {
    return (
      <NativeKeyboardTrackingView {...this.props} />
    );
  }
}
