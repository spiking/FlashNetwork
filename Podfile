# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'FabSocialNetwork' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Alamofire', '~> 3.3'
  pod 'EZLoadingActivity'
  pod 'MBProgressHUD', '~> 0.9.2'
  pod 'JSSAlertView'
  pod 'BTNavigationDropdownMenu'
  pod 'AsyncSwift'
  pod 'SlackTextViewController'
  pod 'JSQMessagesViewController'
  pod 'OneSignal'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
