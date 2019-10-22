Pod::Spec.new do |s|
  s.name = "Endpoints"
  s.version = "2.0.0"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "Type-Safe Swift Networking"
  s.homepage = "https://github.com/tailoredmedia/Endpoints"
  s.authors = { "Peter Weishapl" => "pw@tailored-apps.com",
                "Robin Mayerhofer" => "rm@tailored-apps.com" }
  s.source = {
      :git => "https://github.com/tailoredmedia/Endpoints.git",
      :tag => s.version
  }

  s.ios.deployment_target = "8.0"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"

  s.source_files = "Sources/**/*.swift"
  s.frameworks  = "Foundation"

  s.swift_versions = "5.0"
end
