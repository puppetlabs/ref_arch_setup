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

      master_tarball_path = handle_pe_tarball(pe_tarball_path, target_master)

      params = {}

      # TODO: master_conf_path?
      params["pe_conf_path"] = pe_conf_path

      # params["pe_tarball_path"] = pe_tarball_path
      params["pe_tarball_path"] = master_tarball_path

      BoltHelper.run_task_with_bolt("ref_arch_setup::install_pe", params, target_master)
    end

    # Handles user inputted pe.conf or if nil assumes it is in the CWD
    # Validates file exists (allows just a dir to be given if pe.conf is in it)
    # Also ensures the file is names pe.conf
    # TODO Ensure it is valid once we have a reader/validator class
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

    # Determines whether the specified path is a valid URL
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball_path Path to PE tarball file
    #
    # @return [true,false] Based on whether the path is a valid URL
    def valid_tarball_url?(pe_tarball_path)
      require "uri"
      require "open-uri"
      valid = false
      valid = true if pe_tarball_path =~ /\A#{URI.regexp(%w[http https])}\z/
      return valid
    end

    # Determines whether the specified path has a valid extension (.gz)
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball_path Path to PE tarball file
    #
    # @return [true,false] Based on the validity of the extension
    def valid_extension?(pe_tarball_path)
      valid = false
      extension = File.extname(pe_tarball_path)
      if extension == ".gz"
        valid = true
      else
        puts "Invalid extension: #{extension} for URL: #{pe_tarball_path}."
        puts "Extension must be .gz"
        puts
      end
      valid
    end

    # Determines whether the specified path exists on the target master
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball_path Path to PE tarball file
    # @param [string] target_master Host to install on
    #
    # @return [true,false] Based on whether the path is a valid URL
    def file_exist_on_target_master?(pe_tarball_path, target_master)
      command = "[ -f #{pe_tarball_path} ]"
      exists = BoltHelper.run_cmd_with_bolt(command, target_master)
      return exists
    end

    # Runs the download_pe_tarball Bolt task
    #
    # @author Bill Claytor
    #
    # @param [string] url The pe tarball URL
    # @param [string] nodes Nodes where the task should be run
    #
    # @return [true,false] Based on exit status of the bolt task
    def download_pe_tarball(url, nodes)
      puts "Attempting to download #{url} to #{nodes}"
      puts

      params["url"] = url
      params["destination"] = TMP_WORK_DIR

      success = BoltHelper.run_task_with_bolt("ref_arch_setup::download_pe_tarball", params, nodes)
      return success
    end

    # Downloads the PE tarball locally and moves it to the target master
    #
    # @author Bill Claytor
    #
    # @param [string] url The pe tarball URL
    # @param [string] filename The pe tarball filename
    # @param [string] target_master Host to install on
    #
    # @return [true,false] Based on exit status of the bolt task
    def download_and_move_pe_tarball(url, filename, target_master)
      puts "Attempting to download #{url} to localhost and move to #{target_master}"
      puts

      success = download_pe_tarball(url, "localhost")
      success = upload_pe_tarball("#{TMP_WORK_DIR}/#{filename}") if success
      return success
    end

    # Downloads the specified PE tarball URL by either downloading directly to the
    # target master or downloading locally and copying to the target master
    #
    # @author Bill Claytor
    #
    # @param [string] url The pe tarball URL
    # @param [string] target_master Host to install on
    #
    # @return [true,false] Based on exit status of the bolt task
    def handle_tarball_url(url, target_master)
      uri = URI.parse(pe_tarball_path)
      filename = File.basename(uri.path)

      # TODO: improve check for localhost
      if target_master.equal?("localhost")

        # destination = default
        success = download_pe_tarball(url, target_master)
        raise "Failed downloading #{url} to #{target_master}" unless success

      else

        puts "Specified target master #{target_master} is not localhost"
        puts

        success = download_pe_tarball(url, target_master)

        # if at first you don't succeed...
        puts "Failed download attempt to #{target_master}." unless success
        success = download_and_move_pe_tarball(url, filename, target_master) unless success

        raise "Failed downloading #{url} to localhost and moving to #{target_master}" unless success

      end

      return filename
    end

    # Copies the PE tarball from the specified location to the temp working directory
    # on the target master
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball_path The pe tarball path
    # @param [string] target_master Host to install on
    #
    # @return [true,false] Based on exit status of the bolt task
    def copy_pe_tarball(pe_tarball_path, target_master)
      filename = File.basename(pe_tarball_path)
      command = "cp #{pe_tarball_path} #{TMP_WORK_DIR}/#{filename}"
      success = BoltHelper.run_cmd_with_bolt(command, target_master)
      return success
    end

    # Handles the specified tarball path when the target master is not localhost
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball_path The pe tarball path
    # @param [string] target_master Host to install on
    #
    # @return [true,false] Based on exit status of the bolt task
    def handle_tarball_with_remote_target_master(pe_tarball_path, target_master)
      remote_flag = "#{target_master}:"

      if pe_tarball_path.start_with?(remote_flag)
        tarball_path = pe_tarball_path.sub!(remote_flag, "")
        success = file_exist_on_target_master?(tarball_path, target_master)
        success = copy_pe_tarball(tarball_path, target_master) if success
      else
        success = File.exist?(pe_tarball_path)
        success = upload_pe_tarball(pe_tarball_path) if success
      end

      return success
    end

    # Handles the specified tarball path
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball_path The pe tarball path
    # @param [string] target_master Host to install on
    #
    # @return [true,false] Based on exit status of the bolt task
    def handle_tarball_path(pe_tarball_path, target_master)
      filename = File.basename(pe_tarball_path)
      error = "File not found: #{pe_tarball_path}"

      # TODO: improve check for localhost
      if target_master.equal?("localhost")
        raise(error) unless File.exist?(pe_tarball_path)
        success = upload_pe_tarball(pe_tarball_path)
      else

        success = handle_tarball_with_remote_target_master(pe_tarball_path, target_master)

      end

      raise("Unable to copy tarball to working directory") unless success

      return filename
    end

    # Handles the PE tarball based on the the path (URL / file)
    # and target master (local / remote)
    #
    # TODO: Ensure it is valid once we have a reader/validator class
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball_path Path to PE tarball file
    # @param [string] target_master Host to install on
    #
    # @return [string] The tarball path on the master after copying if successful
    def handle_pe_tarball(pe_tarball_path, target_master)
      raise "Invalid tarball path: #{pe_tarball_path}" unless valid_extension?(pe_tarball_path)

      filename = if valid_tarball_url?(pe_tarball_path)
                   handle_tarball_url(pe_tarball_path, target_master)
                 else
                   handle_tarball_path(pe_tarball_path, target_master)
                 end

      raise "Unable to handle the specified PE tarball path: #{pe_tarball_path}" unless filename

      master_tarball_path = "#{TMP_WORK_DIR}/#{filename}"

      return master_tarball_path
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
