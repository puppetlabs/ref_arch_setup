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
    def bootstrap_mono(pe_conf_path, pe_tarball_path, target_master = @target_master)
      params = {}
      params["pe_conf_path"] = pe_conf_path
      params["pe_tarball_path"] = pe_tarball_path
      params["pe_target_master"] = target_master
      BoltHelper.run_task_with_bolt("ref_arch_setup::install_pe", params, target_master)
    end

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
