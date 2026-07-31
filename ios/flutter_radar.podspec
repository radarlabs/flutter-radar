Pod::Spec.new do |s|
  s.name             = 'flutter_radar'
  s.version          = '3.23.4'
  s.summary          = 'Flutter package for Radar, the leading geofencing and location tracking platform'
  s.description      = 'Flutter package for Radar, the leading geofencing and location tracking platform'
  s.homepage         = 'https://github.com/radarlabs/flutter-radar'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Radar Labs, Inc.' => 'support@radar.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.vendored_frameworks = 'Frameworks/RadarSDK.xcframework',
                          'Frameworks/RadarSDKMotion.xcframework',
                          'Frameworks/RadarSDKFraud.xcframework'
  s.ios.deployment_target = '15.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end