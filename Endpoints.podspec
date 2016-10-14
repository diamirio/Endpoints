Pod::Spec.new do |s|

  s.name = "Endpoints"
  s.version = "0.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Endpoints"
  s.homepage = "https://www.tailored-apps.com"
  s.author = { "Peter Weishapl" => "pw@tailored-apps.com" }
  s.source = { :git => 'https://gitlab.tailored-apps.com/ios/endpoints.git' }

  s.ios.deployment_target = '8.0'

  s.subspec 'Core' do |cs|
    s.source_files = 'Endpoints/*.swift'
  end

  s.subspec 'Mapper' do |cs|
    s.source_files = 'EndpointsMapper/*.swift'
    cs.dependency 'Endpoints/Core'
    s.dependency 'ObjectMapper', '~> 2.1'
  end
end
