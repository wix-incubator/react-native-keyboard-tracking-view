/**
 * Created by artald on 15/05/2016.
 */

import React, {Component} from 'react';
import {requireNativeComponent, findNodeHandle, NativeModules} from 'react-native';

const NativeKeyboardTrackingView = requireNativeComponent('KeyboardTrackingView', null);
const KeyboardTrackingManager = NativeModules.KeyboardTrackingManager;

export default class KeyboardTrackingView extends React.Component {

	constructor(props) {
		super(props);
	}

	render() {
		return (
		  <NativeKeyboardTrackingView {...this.props} />
    );
	}
}