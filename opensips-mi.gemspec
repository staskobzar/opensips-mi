# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opensips/mi/version'

Gem::Specification.new do |spec|
  spec.name          = "opensips-mi"
  spec.version       = Opensips::MI::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["Stas Kobzar"]
  spec.email         = ["staskobzar@gmail.com"]
  spec.description   = %q{Ruby module for interacting with OpenSIPs management interface}
  spec.summary       = %q{OpenSIPs management interface}
  spec.homepage      = "http://github.com/staskobzar/opensips-mi"

  spec.files         = `git ls-files`.split($/).reject{|f| %r|^examples/.*|.match f}
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "xmlrpc", "~> 0.3"

  spec.add_development_dependency "bundler", "~>2.2.5"
  spec.add_development_dependency "rake", "~>13.0.3"
  spec.add_development_dependency "rspec", "~>3.10.0"
end
