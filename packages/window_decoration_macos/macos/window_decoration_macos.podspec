#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint window_decoration_macos.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'window_decoration_macos'
  s.version          = '0.1.0'
  s.summary          = 'macOS implementation of the window_decoration plugin.'
  s.description      = <<-DESC
macOS implementation of the window_decoration plugin using Objective-C FFI.
                       DESC
  s.homepage         = 'https://github.com/rkishan516/window_decoration'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Kishan R' => 'rkishan516@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
