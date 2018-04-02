# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ref_arch_setup/version"

Gem::Specification.new do |spec|
  spec.name             = "ref_arch_setup"
  spec.version          = RefArchSetup::Version::STRING
  spec.authors          = ["Puppet, Inc."]
  spec.email            = ["qa@puppet.com"]
  spec.summary          = "Tool for setting up reference architectures"
  spec.description      = "This gem provides methods for for setting up /
                                Puppet Enterprise reference architectures"
  # spec.homepage        = "/
  # https://github.com/puppetlabs/qatools/tools/ref_arch_setup"
  spec.license          = "Apache-2.0"
  spec.specification_version = 3

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.6"
  # spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"

  # Documentation dependencies
  spec.add_development_dependency "yard", "~> 0"
  # spec.add_development_dependency "markdown", "~> 0"

  # Run time dependencies
  spec.require_paths = "lib"
  spec.bindir        = "bin"
  spec.executables   = %w[ref_arch_setup]

  # Ensure the gem is build out of the versioned files
  spec.files      = Dir["{lib,spec}/**/*", "bin/*", "README*"]
  spec.test_files = `git ls-files -- spec/*`.split("\n")
end
