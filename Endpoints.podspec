Pod::Spec.new do |s|

  s.name = "Endpoints"
  s.version = "0.2"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Endpoints"
  s.homepage = "https://www.tailored-apps.com"
  s.author = { "Peter Weishapl" => "pw@tailored-apps.com" }
  s.source = {
      :git => 'git@gitlab.tailored-apps.com:ios/endpoints.git',
      :tag => s.version
  }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.subspec 'Core' do |sp|
    sp.source_files = 'Endpoints/*.swift'
    sp.pod_target_xcconfig = {
  		'OTHER_SWIFT_FLAGS[config=Debug]' => '-DDEBUG'
	}
  end

  s.subspec 'Mapper' do |sp|
    sp.source_files = 'EndpointsMapper/*.swift'
    sp.dependency 'Endpoints/Core'
    sp.dependency 'ObjectMapper', '~> 2.2'
  end

  s.subspec 'Unbox' do |sp|
    sp.source_files = 'EndpointsUnbox/*.swift'
    sp.dependency 'Endpoints/Core'
    sp.dependency 'Unbox', '~> 2.2'
  end
end
