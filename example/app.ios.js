/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */
import React, {Component} from 'react';
import {AppRegistry, StyleSheet, Text, View, Image, ScrollView, TextInput, TouchableOpacity, Keyboard, Dimensions, PixelRatio} from 'react-native';
// import {BlurView} from 'react-native-blur';
import {KeyboardTrackingView} from 'react-native-keyboard-tracking-view';
import {AutoGrowingTextInput} from 'react-native-autogrow-textinput';

const screenSize = Dimensions.get('window');
const trackInteractive = true;
const Images = [
	'https://static.pexels.com/photos/50721/pencils-crayons-colourful-rainbow-50721.jpeg',
	'https://static.pexels.com/photos/60628/flower-garden-blue-sky-hokkaido-japan-60628.jpeg'
];

const KeyboardToolbar = ({ onActionPress, onLayout, inputRefCallback, trackingRefCallback}) =>
	<KeyboardTrackingView
		style={styles.trackingToolbarContainer}
		onLayout={onLayout}
		trackInteractive={trackInteractive}
		ref={(r) => trackingRefCallback && trackingRefCallback(r)}
	>
	
		<View style={styles.inputContainer}>		
      <AutoGrowingTextInput
        minHeight={38}
        maxHeight={200}
        style={styles.textInput}
        ref={(r) => inputRefCallback && inputRefCallback(r)}
        placeholder={'Message'}
				/>
			<TouchableOpacity style={styles.sendButton} onPress={onActionPress}>
				<Text>Action</Text>
			</TouchableOpacity>
				</View>
	</KeyboardTrackingView>;

class example extends Component {
	render() {
		return (
			<View style={styles.container}>
				<ScrollView
					contentContainerStyle={styles.scrollContainer}
					keyboardDismissMode={trackInteractive ? 'interactive' : 'none'}
				>
					<Text style={styles.welcome}>Keyboard tracking view example</Text>
					{Images.map((image, index) => (<Image style={styles.image} source={{ uri: image }} key={index} />))}
				</ScrollView>
				<KeyboardToolbar
					onActionPress={() => this._textInput._textInput.blur()}
					inputRefCallback={(r) => this._textInput = r}
				/>
			</View>
		);
	}
}

const styles = StyleSheet.create({
	container: {
		flex: 1,
		backgroundColor: '#F5FCFF'
	},
	scrollContainer: {
		justifyContent: 'center',
		padding: 15
	},
	welcome: {
		fontSize: 20,
		textAlign: 'center',
		margin: 10,
		paddingTop: 50,
		paddingBottom: 50
	},
	image: {
		height: 250,
		width: undefined,
		marginBottom: 10
	},
	trackingToolbarContainer: {
		position: 'absolute',
		bottom: 0,
		left: 0,
		width: screenSize.width,
		borderWidth: 0.5 / PixelRatio.get()
	},
	inputContainer: {
		flex: 1,
		flexDirection: 'row',
		alignItems: 'center',
		justifyContent: 'space-between',
    paddingLeft: 15,
    paddingRight: 15,
    paddingTop: 5,
		paddingBottom: 5,
		backgroundColor: 'white'
	},
	textInput: {
    flex: 1,
    fontSize: 17,
		backgroundColor: 'white',
		borderWidth: 0.5 / PixelRatio.get(),
		borderRadius: 19,
    paddingTop: 8,
    paddingBottom: 5,
    paddingLeft: 15,
	},
	sendButton: {
		paddingRight: 15,
		paddingLeft: 15
	}
});

AppRegistry.registerComponent('ReactNativeKeyboardTrackingView', () => example);
