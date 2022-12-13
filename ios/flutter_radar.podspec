Pod::Spec.new do |s|
  s.name             = 'flutter_radar'
  s.version          = '3.1.1'
  s.summary          = 'Flutter package for Radar, the leading geofencing and location tracking platform'
  s.description      = 'Flutter package for Radar, the leading geofencing and location tracking platform'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Radar Labs, Inc.' => 'support@radar.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'RadarSDK', '3.5.9'
  s.platform = :ios, '10.0'
  s.static_framework = true

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
end
