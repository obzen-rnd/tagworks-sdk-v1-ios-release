# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'TagWorks-SDK-iOS-v1' do
  # Comment the next line if you don't want to use dynamic frameworks
  # Swift 프로젝트에서는 이 줄을 추가
  use_frameworks!
  
  # 의존성 라이브러리 추가
  # pod 'CryptoSwift', '~> 1.3.8'

  target 'TagWorks-SDK-iOS-v1Tests' do
    # 메인 타겟에서 의존성 상속
    inherit! :search_paths
    # Pods for testing
  end
end



post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
      end
    end
  end
end