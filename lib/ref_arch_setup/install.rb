# General namespace for RAS
module RefArchSetup
  # A space to use as a default location to put files on target_host
  TMP_WORK_DIR = "/tmp/ref_arch_setup".freeze

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
    def bootstrap(pe_conf_path, pe_tarball_path, target_master = @target_master)
      make_tmp_work_dir(target_master)
      handle_pe_conf(pe_conf_path)
      params = {}
      params["pe_conf_path"] = pe_conf_path
      params["pe_tarball_path"] = pe_tarball_path
      params["pe_target_master"] = target_master
      BoltHelper.run_task_with_bolt("ref_arch_setup::install_pe", params, target_master)
    end

    # Handles user inputted pe.conf or if nil assumes it is in the CWD
    # Validates file exists (allows just a dir to be given if pe.conf is in it)
    # Also ensures the file is names pe.conf
    # TODO Ensure it is valid once we have a reader/validator
    # Move it to the target_master
    #
    # @author Randell Pelak
    #
    # @param [string] pe_conf_path Path to pe.conf file
    #
    # @return [true,false] Based on exit status of the bolt task
    # rubocop:disable Metrics/PerceivedComplexity
    def handle_pe_conf(pe_conf_path)
      if pe_conf_path.nil?
        file_path = Dir.pwd + "/pe.conf"
        raise("No pe.conf file found in current working directory") unless File.exist?(file_path)
      else
        file_path = File.expand_path(pe_conf_path)
        if File.directory?(file_path)
          full_path = file_path + "/pe.conf"
          raise("No pe.conf file found in directory: #{file_path}") unless File.exist?(full_path)
          file_path = full_path
        else
          raise("pe.conf file not found #{file_path}") unless File.exist?(file_path)
        end
      end
      success = upload_pe_conf(file_path)
      return success
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # Creates a tmp work dir for ref_arch_setup on the target_host
    # Doesn't fail if the dir is already there.
    #
    # @author Randell Pelak
    #
    # @param [string] target_master Host to make the dir on
    #
    # @return [true,false] Based on exit status of the bolt task
    def make_tmp_work_dir(target_master = @target_master)
      success = BoltHelper.make_dir(TMP_WORK_DIR, target_master)
      return success
    end

    # Upload the pe.conf to the target_host
    #
    # @author Randell Pelak
    #
    # @param [string] src_pe_conf_path Path to the source copy of the pe.conf file
    # @param [string] dest_pe_conf_path Path to put the pe.conf at on the target host
    # @param [string] target_master Host to upload to
    #
    # @return [true,false] Based on exit status of the bolt task
    def upload_pe_conf(src_pe_conf_path = "#{RAS_FIXTURES_PATH}/pe.conf",
                       dest_pe_conf_path = "#{TMP_WORK_DIR}/pe.conf",
                       target_master = @target_master)
      return BoltHelper.upload_file(src_pe_conf_path, dest_pe_conf_path, target_master)
    end

    # Upload the pe tarball to the target_host
    #
    # @author Randell Pelak
    #
    # @param [string] src_pe_tarball_path Path to the source copy of the tarball file
    # @param [string] dest_pe_tarball_path Path to put the tarball at on the target host
    # @param [string] target_master Host to upload to
    #
    # @return [true,false] Based on exit status of the bolt task
    def upload_pe_tarball(src_pe_tarball_path, dest_pe_tarball_path = TMP_WORK_DIR, \
                          target_master = @target_master)
      if dest_pe_tarball_path == TMP_WORK_DIR
        file_name = File.basename(src_pe_tarball_path)
        dest_pe_tarball_path += "/#{file_name}"
      end
      return BoltHelper.upload_file(src_pe_tarball_path, dest_pe_tarball_path, target_master)
    end
  end
end
