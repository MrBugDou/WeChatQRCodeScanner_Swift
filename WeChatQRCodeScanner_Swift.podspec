#
# Be sure to run `pod lib lint WeChatQRCodeScanner_Swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name = "WeChatQRCodeScanner_Swift"
  s.version = "1.0.0"
  s.summary = "WeChatQRCodeScanner_Swift."
  s.description = <<-DESC
  微信开源二维码识别引擎Swift版本
                       DESC

  s.homepage = "https://github.com/MrBugDou/WeChatQRCodeScanner_Swift"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.author = { "MrBugDou" => "bg1859710@gmail.com" }
  s.source = { :git => "https://github.com/MrBugDou/WeChatQRCodeScanner_Swift.git", :tag => s.version.to_s }

  s.swift_version = "5.0"
  s.ios.deployment_target = "9.0"

  s.source_files = [
    # "WeChatQRCodeScanner/Classes/**/*",
    "WeChatQRCodeScanner/Classes/*.{swift,h}",
  ]
  
  s.preserve_paths = [
  "WeChatQRCodeScanner/Frameworks",
  "WeChatQRCodeScanner/Models",
  # 'patch',
  # 'script/build.sh'
  "script/downloadlib.sh",
  ]
  
  #   s.prepare_command =<<-CMD
  #     script/build.sh "4.6.0"
  #   CMD
  
  s.prepare_command = <<-CMD
  script/downloadlib.sh "lib-v1"
  CMD

  s.vendored_frameworks = [
    "WeChatQRCodeScanner/Frameworks/*.framework",
  ]

  s.resource_bundles = {
    "WeChatQRCodeScanner" => [
      "WeChatQRCodeScanner/Models/*/**"
    ],
  }

  resourceBundleName = "WeChatQRCodeScanner"
  s.script_phases = [
    { :name => "R.swift",
     :execution_position => :before_compile,
     :script => %Q{POD_SRC_DIR="$PODS_TARGET_SRCROOT/#{resourceBundleName}"
      [ ! -d "$POD_SRC_DIR" ] && echo "Can't find SourcesDir of #{s.name}" && exit 1
      if [ $ACTION != "indexbuild" ]; then
      "$PODS_ROOT/R.swift/rswift" generate --target "#{s.name}-#{resourceBundleName}" "$PODS_TARGET_SRCROOT/#{resourceBundleName}/Classes/#{resourceBundleName}.generated.swift"
      sed -i '' -e "s/Bundle(for: R.Class.self)/Bundle.codeScanner/g" "$PODS_TARGET_SRCROOT/#{resourceBundleName}/Classes/#{resourceBundleName}.generated.swift"
      fi
    }.gsub(/[ \t]+/, " ").strip,
     :output_files => [%Q{
    '$PODS_TARGET_SRCROOT/#{resourceBundleName}/Classes/#{resourceBundleName}.generated.swift'
    }.gsub(/[ \t]+/, " ").strip] },
  ]

  s.dependency "R.swift"

  # s.prefix_header_file = false
  s.pod_target_xcconfig = {
    #     'OTHER_CPLUSPLUSFLAGS' => '-fmodules -fcxx-modules'
    "CLANG_WARN_DOCUMENTATION_COMMENTS" => "NO",
    "VALID_ARCHS" => "arm64 x86_64",
    "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64",
  }

  #   s.user_target_xcconfig = {
  #     'OTHER_CPLUSPLUSFLAGS' => '-fmodules -fcxx-modules'
  #   }

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
