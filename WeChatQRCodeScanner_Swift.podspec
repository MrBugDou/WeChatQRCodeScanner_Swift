#
# Be sure to run `pod lib lint WeChatQRCodeScanner_Swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = "WeChatQRCodeScanner_Swift"
  s.version = "1.0.2"
  s.summary = "WeChatQRCodeScanner_Swift."
  s.description = <<-DESC
  微信开源二维码识别引擎Swift版本
                       DESC

  s.homepage = "https://github.com/MrBugDou/WeChatQRCodeScanner_Swift"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "MrBugDou" => "bg1859710@gmail.com" }
  s.source = { :git => "https://github.com/MrBugDou/WeChatQRCodeScanner_Swift.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.static_framework = true
  s.swift_version = "5.8"
  s.ios.deployment_target = "9.0"

  s.source_files = [
    # "WeChatQRCodeScanner/Classes/Objc/*",
    "WeChatQRCodeScanner/Classes/*.{swift,h,mm}",
  ]

  s.preserve_paths = [
    "WeChatQRCodeScanner/Frameworks",
    "WeChatQRCodeScanner/Models",
    # 'patch',
    # 'script/build.sh',
    "script/downloadlib.sh",
  ]

  # s.prepare_command = <<-CMD
  #     script/build.sh "4.9.0"
  # CMD

  s.prepare_command = <<-CMD
   script/downloadlib.sh "lib-v4.9.0"
   CMD

  s.vendored_frameworks = [
    # "WeChatQRCodeScanner/Frameworks/*.framework",
    "WeChatQRCodeScanner/Frameworks/*.xcframework",
  ]

  s.resource_bundles = {
    "WeChatQRCodeScanner" => [
      "WeChatQRCodeScanner/Models/*/**",
    ],
  }

  s.pod_target_xcconfig = {
    "VALID_ARCHS" => "arm64 x86_64",
    "CLANG_WARN_DOCUMENTATION_COMMENTS" => "NO",
    "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64",
  }

  s.frameworks = [
    "AVFoundation",
    "CoreImage",
    "CoreGraphics",
    "QuartzCore",
    "Accelerate",
    "CoreVideo",
    "CoreMedia",
  ]

  s.libraries = [
    "c++",
  ]
end
