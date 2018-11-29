# General namespace for RAS
module RefArchSetup
  %w[cli bolt_helper download_helper version install].each do |lib|
    require "ref_arch_setup/#{lib}"
  end
  # the location of ref_arch_setup
  RAS_PATH = File.dirname(__FILE__) + "/..".freeze
  # location of modules shipped with RAS (Ref Arch Setup)
  RAS_MODULE_PATH = "#{RAS_PATH}/modules".freeze
  # location of fixtures shipped with RAS (Ref Arch Setup)
  RAS_FIXTURES_PATH = "#{RAS_PATH}/fixtures".freeze
end
