require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "ReactNativeBeaconsManager"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = "https://github.com/chilemuesli/react-native-beacons-manager#readme"
  s.license      = { :type => "MIT" }
  s.authors      = { "" => "" }
  s.platforms    = { :ios => "15.1" }
  s.source       = { :git => "https://github.com/chilemuesli/react-native-beacons-manager.git", :tag => "v#{s.version}" }
  s.source_files = "ios/RNiBeacon/RNiBeacon/**/*.{h,m,mm}"
  s.frameworks   = "CoreLocation", "CoreBluetooth"

  # Adds React-Core, codegen and TurboModule dependencies (New Architecture).
  install_modules_dependencies(s)
end
