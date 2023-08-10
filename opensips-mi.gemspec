# frozen_string_literal: true

require_relative "lib/opensips/mi/version"

Gem::Specification.new do |spec|
  spec.name = "opensips-mi"
  spec.version = Opensips::MI::VERSION
  spec.authors = ["Stas Kobzar"]
  spec.email = ["staskobzar@gmail.com"]

  spec.summary = "Ruby OpenSIPs management interface"
  spec.description = "Ruby module for interacting with OpenSIPs management interface. " \
                     "Supports OpenSIPS v3+ MI with JSON-RPC protocol"
  spec.homepage = "https://github.com/staskobzar/opensips-mi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org/gems/opensips-mi"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/staskobzar/opensips-mi"
  spec.metadata["changelog_uri"] = "https://github.com/staskobzar/opensips-mi/releases"
  spec.metadata["github_repo"] = "https://github.com/staskobzar/opensips-mi.git"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ examples/ spec/ features/ .git .github .rspec .rubocop.yml .gitignore])
    end
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "xmlrpc", "~> 0.3"
end
