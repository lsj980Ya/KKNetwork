Pod::Spec.new do |s|
  s.name             = 'KKNetwork'
  s.version          = '1.0.0'
  s.summary          = '基于 Alamofire 和 SwiftyJSON 的完整网络请求框架'
  s.description      = <<-DESC
  KKNetwork 是一个功能完善的网络请求框架，参考 YTKNetwork 设计思路，
  基于 Alamofire 和 SwiftyJSON 实现。支持请求重试、域名切换、缓存、
  拦截器、批量请求、链式请求等功能。
                       DESC

  s.homepage         = 'https://github.com/yourusername/KKNetwork'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :git => 'https://github.com/yourusername/KKNetwork.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'KKNetwork/**/*.swift'
  
  s.dependency 'Alamofire', '~> 5.6'
  s.dependency 'SwiftyJSON', '~> 5.0'
  
  s.frameworks = 'Foundation'
end
