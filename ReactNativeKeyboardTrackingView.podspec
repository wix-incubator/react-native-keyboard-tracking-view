require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "ReactNativeKeyboardTrackingView"
  s.version      = package['version']
  s.summary      = "React Native Keyboard Tracking View"

  s.authors      = "Wix.com"
  s.homepage     = package['homepage']
  s.license      = package['license']
  s.platforms    = { :ios => "9.0", :tvos => "9.2" }

  s.module_name  = 'ReactNativeKeyboardTrackingView'

  s.source       = { :git => "https://github.com/wix/react-native-keyboard-tracking-view", :tag => "#{s.version}" }
  s.source_files  = "lib/**/*.{h,m}"

  s.dependency 'React'
  s.frameworks = 'UIKit'
end
