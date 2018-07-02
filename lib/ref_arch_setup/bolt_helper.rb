# General namespace for RAS
module RefArchSetup
  # Bolt helper methods
  module BoltHelper
    # Creates a dir on the target_host
    # Doesn't fail if dir is already there
    # Uses -p to create parent dirs if needed
    #
    # @author Randell Pelak
    #
    # @param [string] dir Directory to create
    # @param [string] nodes Hosts to make dir on
    #
    # @return [true,false] Based on exit status of the bolt task
    def self.make_dir(dir, nodes)
      cmd = "[ -d #{dir} ] || mkdir -p #{dir}"
      success = run_cmd_with_bolt(cmd, nodes)
      puts "ERROR: Failed to make dir #{dir} on all nodes" unless success
      return success
    end

    # Run a command with bolt on given nodes
    #
    # @author Randell Pelak
    #
    # @param [string] cmd Command to run on nodes
    # @param [string] nodes Host to make dir on
    #
    # @return [true,false] Based on exit status of the bolt task
    def self.run_cmd_with_bolt(cmd, nodes)
      command = "bolt command run '#{cmd}'"
      command << " --nodes #{nodes}"
      puts "Running: #{command}"
      output = `#{command}`
      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "ERROR: bolt command failed!" unless success
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      puts "Output was: #{output}"
      return success
    end

    # Run a task with bolt on given nodes
    #
    # @author Sam Woods
    #
    # @param task [string] Task to run on nodes
    # @param params [hash] task parameters to send to bolt
    # @param nodes [string] Host or space delimited hosts to run task on
    #
    # @return [true,false] Based on exit status of the bolt task
    def self.run_task_with_bolt(task, params, nodes)
      params_str = ""
      params_str = params_to_string(params) unless params.nil?
      command = "bolt task run #{task} #{params_str}"
      command << " --modulepath #{RAS_MODULE_PATH} --nodes #{nodes}"
      puts "Running: #{command}"
      output = `#{command}`
      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "ERROR: bolt task failed!" unless success
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      puts "Output was: #{output}"
      return success
    end

    # Convert params to string for bolt
    # format is space separated list of name=value
    #
    # @author Randell Pelak
    #
    # @param params [Array] params to convert
    #
    # @return [String] stringified params
    def self.params_to_string(params)
      # str = ""
      str = params.map { |k, v| "#{k}=#{v}" }.join(" ")
      return str
    end

    # Upload a file to given nodes
    #
    # @author Randell Pelak
    #
    # @param [string] source File to upload
    # @param [string] destination Path to upload to
    # @param [string] nodes Host to put files on
    #
    # @return [true,false] Based on exit status of the bolt task
    def self.upload_file(source, destination, nodes)
      command = "bolt file upload #{source} #{destination}"
      command << " --nodes #{nodes}"
      puts "Running: #{command}"
      output = `#{command}`
      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "ERROR: failed to upload file #{source} to #{destination} on #{nodes}" unless success
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      puts "Output was: #{output}"
      return success
    end
  end
end
