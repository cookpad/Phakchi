Pod::Spec.new do |s|
  s.name         = "Phakchi"
  s.version      = "2.0.0"
  s.summary      = "A Pact consumer library for iOS"
  s.description  = <<-DESC
                   This library provides a Swift version DSL for creating pacts.
                   DESC
  s.homepage     = "https://github.com/cookpad/Phakchi"
  s.license      = "MIT"
  s.license      = { :type => 'MIT' }
  s.authors      = { "Kohki Miki" => "koki-miki@cookpad.com", "Taiki Ono" => "taiki-ono@cookpad.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/cookpad/Phakchi", :tag => s.version.to_s }
  s.source_files = "Sources/Phakchi/**/*.swift"
  s.resources = 'scripts/start_control_server.sh', 'scripts/stop_control_server.sh'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'UIKit', 'XCTest'
end
