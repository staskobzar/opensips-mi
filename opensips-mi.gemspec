# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opensips/mi/version'

Gem::Specification.new do |gem|
  gem.name          = "opensips-mi"
  gem.version       = Opensips::MI::VERSION
  gem.authors       = ["Stas Kobzar"]
  gem.email         = ["stas@modulis.ca"]
  gem.description   = %q{Ruby module for interacting with OpenSIPs management interface}
  gem.summary       = %q{OpenSIPs management interface}
  gem.homepage      = "http://github.com/staskobzar/opensips-mi"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency('bundler', '~> 1.3')
  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('mocha')
end
