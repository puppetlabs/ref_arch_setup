# coding: utf-8

# place ONLY runtime deps in here (and metadata)
require File.expand_path("../lib/ref_arch_setup/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name             = "ref_arch_setup"
  spec.version          = RefArchSetup::Version::STRING
  spec.authors          = ["Puppet, Inc."]
  spec.email            = ["qa@puppet.com"]
  spec.summary          = "Tool for setting up reference architectures"
  spec.description      = "This gem provides methods for for setting up /
                                Puppet Enterprise reference architectures"
  spec.homepage         = "https://github.com/puppetlabs/ref_arch_setup"
  spec.license          = "Puppet Enterprise License"

  # Ensure the gem is build out of the versioned files
  spec.files            = Dir["CONTRIBUTING.md", "LICENSE.md", "MAINTAINERS",
                              "README.md", "lib/**/*", "bin/*", "docs/**/*"]
  spec.executables   = ["ref_arch_setup"]
  spec.require_paths = ["lib"]

  # Run time dependencies
  spec.add_runtime_dependency "bolt", "~> 0.17"
end
