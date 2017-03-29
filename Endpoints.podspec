Pod::Spec.new do |s|
  s.name = "Endpoints"
  s.version = "0.4.1"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Type-Safe Swift Networking"
  s.homepage = "https://github.com/tailoredmedia/Endpoints"
  s.author = { "Peter Weishapl" => "pw@tailored-apps.com" }
  s.source = {
      :git => "https://github.com/tailoredmedia/Endpoints.git",
      :tag => s.version
  }

  s.ios.deployment_target = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"

  s.source_files = "Sources/*.swift"
  s.frameworks  = "Foundation"
  s.pod_target_xcconfig = {
    "OTHER_SWIFT_FLAGS[config=Debug]" => "-DDEBUG"
  }
end
