import React, {PureComponent} from 'react';
import {View} from 'react-native';

export default class KeyboardTrackingView extends PureComponent {
  constructor(props) {
    super(props);
  }
  render() {
    return (
      <View {...this.props} />
    );
  }
}
