require "uri"
require "open-uri"

# General namespace for RAS
module RefArchSetup
  # A space to use as a default location to put files on target_host
  TMP_WORK_DIR = "/tmp/ref_arch_setup".freeze
  DOWNLOAD_PE_TARBALL_TASK = "ref_arch_setup::download_pe_tarball".freeze
  INSTALL_PE_TASK = "ref_arch_setup::install_pe".freeze

  # Installation helper
  #
  # @author Randell Pelak
  #
  # @attr [string] target_master Host to install on
  #
  # TODO: review the value for ClassLength
  # rubocop:disable Metrics/ClassLength
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
    # @param [string] pe_tarball Path or URL for the pe tarball
    #
    # @return [true,false] Based on exit status of the bolt task
    def bootstrap(pe_conf_path, pe_tarball)
      raise "Unable to create RAS working directory" unless make_tmp_work_dir
      conf_path_on_master = handle_pe_conf(pe_conf_path)
      tarball_path_on_master = handle_pe_tarball(pe_tarball)

      params = {}
      params["pe_conf_path"] = conf_path_on_master
      params["pe_tarball_path"] = tarball_path_on_master

      BoltHelper.run_task_with_bolt(INSTALL_PE_TASK, params, @target_master)
    end

    # Handles user inputted pe.conf or if nil assumes it is in the CWD
    # Validates file exists (allows just a dir to be given if pe.conf is in it)
    # TODO Ensure it is valid once we have a reader/validator class
    # Move it to the target_master
    #
    # @author Randell Pelak
    #
    # @param [string] pe_conf_path Path to pe.conf file or dir
    #
    # @return [string] The path to the pe.conf file on the target master
    def handle_pe_conf(pe_conf_path)
      conf_path_on_master = "#{TMP_WORK_DIR}/pe.conf"
      if pe_conf_path.nil?
        file_path = Dir.pwd + "/pe.conf"
        raise("No pe.conf file found in current working directory") unless File.exist?(file_path)
      else
        file_path = handle_pe_conf_path(pe_conf_path)
      end
      success = upload_pe_conf(file_path)
      raise "Unable to upload pe.conf file to #{@target_master}" unless success

      return conf_path_on_master
    end

    # Handles user inputted pe.conf
    # Validates file exists (allows just a dir to be given if pe.conf is in it)
    # Also ensures the file is named pe.conf
    #
    # @author Randell Pelak
    #
    # @param [string] pe_conf_path Path to pe.conf file or dir
    #
    # @return [string] The path to the pe.conf file
    def handle_pe_conf_path(pe_conf_path)
      file_path = File.expand_path(pe_conf_path)
      if File.directory?(file_path)
        full_path = file_path + "/pe.conf"
        raise("No pe.conf file found in directory: #{file_path}") unless File.exist?(full_path)
        file_path = full_path
      else
        filename = File.basename(file_path)
        raise("Specified file is not named pe.conf #{file_path}") unless filename.eql?("pe.conf")
        raise("pe.conf file not found #{file_path}") unless File.exist?(file_path)
      end

      return file_path
    end

    # Determines whether the specified path is a valid URL
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball Path to PE tarball file
    #
    # @return [true,false] Based on whether the path is a valid URL
    def valid_url?(pe_tarball)
      valid = false
      valid = true if pe_tarball =~ /\A#{URI.regexp(%w[http https])}\z/
      return valid
    end

    # Parses the specified URL
    #
    # @author Bill Claytor
    #
    # @param [string] url URL for the PE tarball file
    #
    # @raise [RuntimeError] Based on the validity of the url
    #
    # @return [true] Based on the validity of the URL
    def parse_url(url)
      begin
        @pe_tarball_uri = URI.parse(url)
        @pe_tarball_filename = File.basename(@pe_tarball_uri.path)
      rescue
        raise "Unable to parse the specified URL: #{url}"
      end
      return true
    end

    # Determines whether the specified path / url has a valid extension (.gz)
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball Path to PE tarball file
    #
    # @raise [RuntimeError] Based on the validity of the extension
    #
    # @return [true] Based on the validity of the extension
    def validate_tarball_extension(pe_tarball)
      message = "Invalid extension for tarball: #{pe_tarball}; extension must be .tar.gz"
      raise(message) unless pe_tarball.end_with?(".tar.gz")
      return true
    end

    # Determines whether the target master is localhost
    #
    # @author Bill Claytor
    #
    # @return [true,false] Based on whether the target master is localhost
    #
    # TODO: (SLV-185) Improve check for localhost
    #
    def target_master_is_localhost?
      is_localhost = false
      is_localhost = true if @target_master.include?("localhost")
      return is_localhost
    end

    # Determines whether the specified file exists on the target master
    #
    # @author Bill Claytor
    #
    # @param [string] path Path to PE tarball file
    #
    # @return [true,false] Based on whether the file exists on the target master
    #
    # TODO: SLV-187 - combine with copy_pe_tarball_on_target_master
    #
    def file_exist_on_target_master?(path)
      command = "[ -f #{path} ]"
      exists = BoltHelper.run_cmd_with_bolt(command, @target_master)
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
    #
    # TODO: update to return the download path (SLV-186)
    #
    def download_pe_tarball(url, nodes)
      puts "Attempting to download #{url} to #{nodes}"
      puts

      params = {}
      params["url"] = url
      params["destination"] = TMP_WORK_DIR

      success = BoltHelper.run_task_with_bolt(DOWNLOAD_PE_TARBALL_TASK, params, nodes)
      return success
    end

    # Downloads the PE tarball locally and moves it to the target master
    #
    # @author Bill Claytor
    #
    # @param [string] url The pe tarball URL
    #
    # @return [true,false] Based on exit status of the bolt task
    def download_and_move_pe_tarball(url)
      download_path = "#{TMP_WORK_DIR}/#{@pe_tarball_filename}"
      success = download_pe_tarball(url, "localhost")
      success = upload_pe_tarball(download_path) if success
      return success
    end

    # Handles the specified PE tarball URL by either downloading directly to the
    # target master or downloading locally and copying to the target master
    #
    # @author Bill Claytor
    #
    # @param [string] url The PE tarball URL
    #
    # @return [string] The tarball path on the target master
    def handle_tarball_url(url)
      parse_url(url)
      tarball_path_on_master = "#{TMP_WORK_DIR}/#{@pe_tarball_filename}"
      remote_error = "Failed downloading #{url} to localhost and moving to #{@target_master}"

      if target_master_is_localhost?
        success = download_pe_tarball(url, "localhost")
        raise "Failed downloading #{url} to localhost" unless success
      else
        # if downloading to the target master fails try to download locally and then upload
        success = download_pe_tarball(url, @target_master)
        puts "Unable to download the tarball directly to #{@target_master}" unless success
        success = download_and_move_pe_tarball(url) unless success
        raise remote_error unless success
      end

      return tarball_path_on_master
    end

    # Copies the PE tarball from the specified location to the temp working directory
    # on the target master
    #
    # @author Bill Claytor
    #
    # @param [string] tarball_path_on_target_master The pe tarball path on the target master
    #
    # @return [true,false] Based on exit status of the bolt task
    def copy_pe_tarball_on_target_master(tarball_path_on_target_master)
      command = "cp #{tarball_path_on_target_master} #{TMP_WORK_DIR}"
      success = BoltHelper.run_cmd_with_bolt(command, @target_master)
      return success
    end

    # Handles the specified tarball path when the target master is not localhost
    #
    # @author Bill Claytor
    #
    # @param [string] path The pe tarball path
    #
    # @return [true,false] Based on exit status of the bolt task
    def handle_tarball_path_with_remote_target_master(path)
      remote_flag = "#{@target_master}:"

      if path.start_with?(remote_flag)
        actual_path = path.sub!(remote_flag, "")
        success = file_exist_on_target_master?(actual_path)
        success = copy_pe_tarball_on_target_master(actual_path) if success
      else
        success = File.exist?(path)
        success = upload_pe_tarball(path) if success
      end

      return success
    end

    # Handles the specified tarball path
    #
    # @author Bill Claytor
    #
    # @param [string] path The PE tarball path
    #
    # TODO: improve "host to install on"? ("host where PE will be installed?")
    #
    # @return [string] The tarball path on the target master
    def handle_tarball_path(path)
      filename = File.basename(path)
      tarball_path_on_master = "#{TMP_WORK_DIR}/#{filename}"
      file_not_found_error = "File not found: #{path}"
      upload_error = "Unable to upload tarball to the RAS working directory on #{@target_master}"
      copy_error = "Unable to copy tarball to the RAS working directory on #{@target_master}"

      if target_master_is_localhost?
        raise file_not_found_error unless File.exist?(path)
        success = upload_pe_tarball(path)
        error = copy_error unless success
      else
        success = handle_tarball_path_with_remote_target_master(path)
        error = upload_error unless success
      end

      raise error unless success

      return tarball_path_on_master
    end

    # Handles the PE tarball based on the the path (URL / file)
    # and target master (local / remote)
    #
    # @author Bill Claytor
    #
    # @param [string] pe_tarball Path to PE tarball file
    #
    # @return [string] The tarball path on the master after copying if successful
    def handle_pe_tarball(pe_tarball)
      error = "Unable to handle the specified PE tarball path: #{pe_tarball}"
      validate_tarball_extension(pe_tarball)
      tarball_path_on_master = if valid_url?(pe_tarball)
                                 handle_tarball_url(pe_tarball)
                               else
                                 handle_tarball_path(pe_tarball)
                               end

      raise error unless tarball_path_on_master

      return tarball_path_on_master
    end

    # Creates a tmp work dir for ref_arch_setup on the target_host
    # Doesn't fail if the dir is already there.
    #
    # @author Randell Pelak
    #
    # @return [true,false] Based on exit status of the bolt task
    def make_tmp_work_dir
      success = BoltHelper.make_dir(TMP_WORK_DIR, @target_master)
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
    #
    # @return [true,false] Based on exit status of the bolt task
    def upload_pe_tarball(src_pe_tarball_path)
      file_name = File.basename(src_pe_tarball_path)
      dest_pe_tarball_path = "#{TMP_WORK_DIR}/#{file_name}"

      puts "Attempting upload from #{src_pe_tarball_path} " \
           "to #{dest_pe_tarball_path} on #{@target_master}"

      return BoltHelper.upload_file(src_pe_tarball_path, dest_pe_tarball_path, @target_master)
    end
  end
end
