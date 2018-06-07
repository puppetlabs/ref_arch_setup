# General namespace for RAS
module RefArchSetup
  %w[cli version install].each do |lib|
    require "ref_arch_setup/#{lib}"
  end
  # location of modules shipped with RAS (Ref Arch Setup)
  RAS_MODULE_PATH = File.dirname(__FILE__) + "/../modules"
end
