import React, {Component} from 'react';
import {AppRegistry, StyleSheet, Text, View} from 'react-native';
import {KeyboardTrackingView} from 'react-native-keyboard-tracking-view';

class example extends Component {
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Keyboard tracking view example - doesn't do much on Android..
        </Text>
        <KeyboardTrackingView style={{backgroundColor: 'green', width: 100}}/>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('ReactNativeKeyboardTrackingView', () => example);
