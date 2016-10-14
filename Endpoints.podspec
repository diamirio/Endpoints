Pod::Spec.new do |s|

  s.name = "Endpoints"
  s.version = "0.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Endpoints"
  s.homepage = "https://www.tailored-apps.com"
  s.author = { "Peter Weishapl" => "pw@tailored-apps.com" }
  s.source = { :git => 'https://gitlab.tailored-apps.com/ios/endpoints.git' }

  s.ios.deployment_target = '8.0'

  s.requires_arc = 'true'
  s.source_files = 'Endpoints/*.swift'
end
