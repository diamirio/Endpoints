Pod::Spec.new do |s|

  s.name = "Endpoints"
  s.version = "0.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Endpoints"
  s.homepage = "https://www.tailored-apps.com"
  s.author = { "Peter Weishapl" => "pw@tailored-apps.com" }
  s.source = { :git => 'https://gitlab.tailored-apps.com/ios/endpoints.git' }

  s.ios.deployment_target = '8.0'

  s.subspec 'Core' do |sp|
    sp.source_files = 'Endpoints/*.swift'
  end

  s.subspec 'Mapper' do |sp|
    sp.source_files = 'EndpointsMapper/*.swift'
    sp.dependency 'Endpoints/Core'
    sp.dependency 'ObjectMapper', '~> 2.1'
  end
end
