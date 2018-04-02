# RefArchSetup
module RefArchSetup
  %w[cli version].each do |lib|
    begin
      require "ref_arch_setup/#{lib}"
    rescue LoadError
      require File.expand_path(File.join(File.dirname(__FILE__), "ref_arch_setup", lib))
    end
  end
end
