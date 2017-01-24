Pod::Spec.new do |s|
  s.name = "Endpoints"
  s.version = "0.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Endpoints"
  s.homepage = "https://www.tailored-apps.com"
  s.author = { "Peter Weishapl" => "pw@tailored-apps.com" }
  s.source = { :git => 'https://gitlab.tailored-apps.com/ios/endpoints.git' }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Sources/*.swift'
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS[config=Debug]' => '-DDEBUG'
  }
end
