# General namespace for RAS
module RefArchSetup
  # Installation helper
  #
  # @author Randell Pelak
  #
  # @attr [string] target_master Host to install on
  class Install
    # Initialize class
    #
    # @author Randell Pelak
    #
    # @param [string] target_master Host to install on
    #
    # @return [void]
    def initialize(target_master)
      @target_master = target_master
    end

    # Runs the initial bootstrapping install
    #
    # @author Randell Pelak
    #
    # @param [string] pe_conf_path Path to pe.conf
    # @param [string] pe_tarball_path Path to pe tarball
    # @param [string] target_master Host to install on
    #
    # @return [true,false] Based on exit status of the bolt task
    def bootstrap_mono(pe_conf_path, pe_tarball_path, target_master = @target_master)
      env_vars = "PE_CONF_PATH=#{pe_conf_path};"
      env_vars << "PE_TARBALL_PATH=#{pe_tarball_path};"
      env_vars << "PE_TARGET_MASTER=#{target_master};"
      command = env_vars.to_s + "bolt task run bogus::foo "
      command << "--modulepath #{RAS_MODULE_PATH} --nodes #{target_master}"
      puts "Running: #{command}"
      output = `#{command}`
      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "ERROR: bolt command failed!" unless success
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      puts "Output was: #{output}"
      return success
    end
  end
end
