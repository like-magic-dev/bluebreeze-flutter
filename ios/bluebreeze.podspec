#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint bluebreeze.podspec` to validate before publishing.
#
require 'yaml'

# Reads this package's own version from pubspec.yaml (the single source of truth, updated by
# tools/bump_version.py) instead of duplicating it here where it could drift out of sync.
pubspec = YAML.load_file(File.join(__dir__, '..', 'pubspec.yaml'))

Pod::Spec.new do |s|
  s.name             = 'bluebreeze'
  s.version          = pubspec['version']
  s.summary          = 'BlueBreeze Flutter SDK.'
  s.description      = <<-DESC
A modern Bluetooth LE library.
                       DESC
  s.homepage         = 'https://likemagic.dev'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Alessandro Mulloni' => 'ale@likemagic.dev' }
  s.source           = { :path => '.' }
  s.source_files     = 'bluebreeze/Sources/bluebreeze/**/*'
  s.dependency         'Flutter'
  s.platform         = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version       = '5.0'

  s.ios.deployment_target  = '13.0'
  s.osx.deployment_target  = '11.5'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'bluebreeze_privacy' => ['Resources/PrivacyInfo.xcprivacy']}

  # Matches Package.swift's `from: "1.0.1"` (>= 1.0.1, < 2.0.0) -- `~>` would cap patch/minor
  # updates at < 1.1.0 and let CocoaPods/SPM consumers drift onto different native versions.
  s.dependency 'BlueBreeze', '>= 1.0.1', '< 2.0.0'
end
