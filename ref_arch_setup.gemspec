# place ONLY runtime deps in here (and metadata)
require File.expand_path("../lib/ref_arch_setup/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name             = "ref_arch_setup"
  spec.version          = RefArchSetup::Version::STRING
  spec.authors          = ["Puppet, Inc."]
  spec.email            = ["team-system-level-validation@puppet.com"]
  spec.summary          = "Tool for setting up reference architectures"
  spec.description      = "This gem provides methods for for setting up /
                                Puppet Enterprise reference architectures"
  spec.homepage         = "https://github.com/puppetlabs/ref_arch_setup"
  spec.license          = "Apache2"

  # Ensure the gem is build out of the versioned files
  spec.files            = Dir["CONTRIBUTING.md", "LICENSE.md", "MAINTAINERS",
                              "README.md", "lib/**/*", "bin/*", "docs/**/*",
                              "fixtures/**/*", "modules/**/*", "Boltdir/**/*"]
  spec.executables   = ["ref_arch_setup"]
  spec.require_paths = ["lib"]

  # Bolt requires Ruby ~> 2.3
  spec.required_ruby_version = ">= 2.3.0"

  # Run time dependencies

  # Development dependencies
  spec.add_development_dependency "beaker", "~>4.0"
  spec.add_development_dependency "beaker-vmpooler"
  spec.add_development_dependency "beaker-docker"
end
