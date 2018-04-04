# RefArchSetup
module RefArchSetup
  %w[cli version].each do |lib|
    require "ref_arch_setup/#{lib}"
  end
end
