/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, {
  AppRegistry,
  Component,
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  TouchableWithoutFeedback,
  requireNativeComponent
} from 'react-native';

const KeyboardTrackingView = requireNativeComponent('KeyboardTrackingView', null);

class example extends Component {
  render() {
    return (
      <TouchableWithoutFeedback onPress={() => this._textInput.blur()}>
        <View style={styles.container}>
          <Text style={styles.welcome}>
            Keyboard tracking view example
          </Text>
          <KeyboardTrackingView style={styles.textInputContainer}>
            <TextInput style={styles.textInput}
                       placeholder={'Message'}
                       ref={(r) => {
                         this._textInput = r;
                       }}
            />
            <TouchableOpacity style={styles.sendButton}
                              onPress={() => this._textInput.blur()} >
              <Text>Dismiss</Text>
            </TouchableOpacity>
          </KeyboardTrackingView>
        </View>
      </TouchableWithoutFeedback>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    backgroundColor: '#F5FCFF'
  },
  welcome: {
    flex: 1,
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
    paddingTop: 50
  },
  textInputContainer: {
    backgroundColor: '#777777',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between'
  },
  textInput: {
    flex: 1,
    height: 35,
    marginLeft: 10,
    marginTop: 10,
    marginBottom: 10,
    paddingLeft: 10,
    fontSize: 17,
    backgroundColor: 'white',
    borderWidth: 0,
    borderRadius: 4
  },
  sendButton: {
    paddingRight: 15,
    paddingLeft: 15
  }
});

AppRegistry.registerComponent('example', () => example);
