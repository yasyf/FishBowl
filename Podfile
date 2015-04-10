source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'SwiftHTTP', '~> 0.9.3'
pod 'SDWebImage', '~>3.7'
pod 'Localytics', '~> 3.0'
pod 'FormatterKit', '~> 1.8.0'

prepare_command = <<-CMD
    SUPPORTED_LOCALES="['base', 'en']"
    find . -type d ! -name "*$SUPPORTED_LOCALES.lproj" | grep .lproj | xargs rm -rf
CMD
