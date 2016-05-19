/**
 * Created by artald on 15/05/2016.
 */

import React, { Component } from 'react';
import {
	requireNativeComponent
} from 'react-native';

const NativeKeyboardTrackingView = requireNativeComponent('KeyboardTrackingView', null);

export default class KeyboardTrackingView extends React.Component {
	render() {
		return <NativeKeyboardTrackingView {...this.props} />;
	}
}