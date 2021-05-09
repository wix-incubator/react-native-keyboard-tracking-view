# Important: deprecation alert
This library is being deprecated and the repository will not be maintaned, the components have moved to our UI library - please start migrating to [RN-UILib](https://github.com/wix/react-native-ui-lib/).  
If you want to try out our excelent (and constantly improving) UI compoenent library, please use:  
```
import {Keyboard} from 'react-native-ui-lib';
const KeyboardTrackingView = Keyboard.KeyboardTrackingView;
```
If you don't want to import the whole library, you can use only the `keyboard` package:  
```
import {KeyboardTrackingView} from 'react-native-ui-lib/keyboard';
```

# react-native-keyboard-tracking-view
A react native UI component that enables “keyboard tracking" for this view and it's sub-views. Would typically be used when you have a TextInput inside this view.

![Demo](https://github.com/wix/react-native-keyboard-tracking-view/blob/master/img/demo.gif)

## Installation

- Install using `npm`:

	```
	npm i react-native-keyboard-tracking-view --save
	```

#### Option: Manually

- Locate the module lib folder in your node modules:
	`PROJECT_DIR/node_modules/react-native-keyboard-tracking-view/lib`.

- Drag the `KeyboardTrackingView.xcodeproj` project file into your project

![](https://github.com/wix/react-native-keyboard-tracking-view/blob/master/img/add_proj.png)

- Add `libKeyboardTrackingView.a` to your target's **Linked Frameworks and Libraries**.

![](https://github.com/wix/react-native-keyboard-tracking-view/blob/master/img/add_lib.png)

#### Option: With [CocoaPods](https://cocoapods.org/)

Add the following to your `Podfile` and run `pod update`:

```
pod 'react-native-keyboard-tracking-view', :path => '../node_modules/react-native-keyboard-tracking-view'
```


## How To Use
Require the native component:

```js
import {KeyboardTrackingView} from 'react-native-keyboard-tracking-view';
```

Now use it in your jsx as the parent of the views you whish to track the keyboard (usually wraps a TextInput at the bottom of the screen):

```jsx
<KeyboardTrackingView style={styles.textInputContainer}>
	<TextInput style={styles.textInput} />
</KeyboardTrackingView>
```

##Native Properties

Attribute | Description
-------- | -----------
trackInteractive | boolean property that enables tracking of the keyboard when it's dismissed interactively. False by default. Why? When using an external keyboard (BT), you still get the keyboard events and the view just hovers when you focus the input. Also, if you're not using interactive style of dismissing the KB (or if you don't have an input inside this view) it doesn't make sense to track it anyway. (This is caused because of the usage of inputAccessory to be able to track the keyboard interactive change and it introduces this bug)


## Example Project

Check out the full example project [here](https://github.com/wix/react-native-keyboard-tracking-view/tree/master/example).

In the example folder, perform `npm install` and then run it from the Xcode project.
