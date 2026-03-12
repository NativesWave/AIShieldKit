Pod::Spec.new do |s|
  s.name             = 'AIShieldKit'
  s.version          = '1.0.1'
  s.summary          = 'Vendor-neutral safety and control utilities for AI-powered iOS apps.'
  s.description      = <<-DESC
AIShieldKit is an open-core Swift library that helps iOS teams add pragmatic
safety and control checks between app code and any AI provider. It includes
heuristic prompt analysis, token/cost estimation, JSON structure validation,
rate limiting, and in-memory caching.
  DESC

  s.homepage         = 'https://github.com/Ahsan-Pitafi/AIShieldKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ahsan Iqbal' => '58457086+Ahsan-Pitafi@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/Ahsan-Pitafi/AIShieldKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '15.0'
  s.swift_versions   = ['5.9', '6.0']
  s.module_name      = 'AIShieldKit'
  s.static_framework = true

  s.source_files     = 'Sources/AIShieldKit/**/*.swift'
  s.frameworks       = 'Foundation'
end
