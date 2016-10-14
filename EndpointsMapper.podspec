Pod::Spec.new do |s|

  s.name = "EndpointsMapper"
  s.version = "0.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "EndpointsMapper"
  s.homepage = "https://www.tailored-apps.com"
  s.author = { "Peter Weishapl" => "pw@tailored-apps.com" }
  s.source = { :git => 'https://gitlab.tailored-apps.com/ios/endpoints.git' }

  s.ios.deployment_target = '8.0'

  s.source_files = 'EndpointsMapper/*.swift'

  s.dependency 'Endpoints', '~> 0.1'
  s.dependency 'ObjectMapper', '~> 2.1'
end
