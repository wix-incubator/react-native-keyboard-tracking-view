require 'json'
version = JSON.parse(File.read('package.json'))["version"]

Pod::Spec.new do |s|

  s.name                  = "react-native-keyboard-tracking-view"
  s.version               = version
  s.summary               = "Keyboard Tracking View for React Native."
  s.homepage              = "https://github.com/wix/react-native-keyboard-tracking-view"
  s.license               = 'MIT'
  s.source                = { path: '.' }
  s.ios.deployment_target = '9.0'
  s.authors               = { 'Artal Druk' => 'artald@wix.com' }
  s.source_files          = 'lib/*.{h,m}'
  s.dependency 'React'

end