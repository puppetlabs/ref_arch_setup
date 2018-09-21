# General namespace for RAS
module RefArchSetup
  # Bolt helper methods
  class BoltHelper
    FORGE_MODULE_PATH = File.dirname(__FILE__) + "/../../Boltdir/modules"
    @bolt_options = {}

    # gets the bolt options as a string
    #
    # @author Sam Woods
    # @return [string] the string value for bolt options
    def self.bolt_options_string
      bolt_options_string = ""
      @bolt_options.each do |key, value|
        bolt_options_string << " --#{key} #{value}"
      end
      bolt_options_string
    end

    # sets the bolt options
    #
    # @author Sam Woods
    #
    # @param [hash] bolt options
    class << self
      attr_writer :bolt_options
    end

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
      raise "ERROR: Failed to make dir #{dir} on all nodes" unless success
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
      command << bolt_options_string
      puts "Running: #{command}"
      output = `#{command}`
      puts "Output was: #{output}"

      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      raise "ERROR: bolt command failed!" unless success

      return success
    end

    # Run a task with bolt on given nodes
    #
    # @author Sam Woods
    #
    # @param task [string] Task to run on nodes
    # @param params [hash] task parameters to send to bolt
    # @param nodes [string] Host or space delimited hosts to run task on
    # @param modulepath [string] The modulepath to use when running bolt
    #
    # @return [true,false] Based on exit status of the bolt task
    def self.run_task_with_bolt(task, params, nodes, modulepath = RAS_MODULE_PATH)
      params_str = ""
      params_str = params_to_string(params) unless params.nil?
      command = "bolt task run #{task} #{params_str}"
      command << " --modulepath #{modulepath} --nodes #{nodes}"
      command << bolt_options_string
      puts "Running: #{command}"
      output = `#{command}`
      puts "Output was: #{output}"

      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      raise "ERROR: bolt task failed!" unless success

      return success
    end

    # Run a plan with bolt on given nodes
    #
    # @author Sam Woods
    #
    # @param plan [string] Plan to run on nodes
    # @param params [hash] Plan parameters to send to bolt
    # @param nodes [string] Host or space delimited hosts to run plan on
    # @param modulepath [string] The modulepath to use when running bolt
    #
    # @return [string] The output from the bolt run
    def self.run_plan_with_bolt(plan, params, nodes, modulepath = RAS_MODULE_PATH)
      params_str = ""
      params_str = params_to_string(params) unless params.nil?
      command = "bolt plan run #{plan} #{params_str}"
      command << " --modulepath #{modulepath} --nodes #{nodes}"
      command << bolt_options_string
      puts "Running: #{command}"
      output = `#{command}`
      puts "Output was: #{output}"

      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      raise "ERROR: bolt plan failed!" unless success

      return output
    end

    # Run a task from the forge with bolt on given nodes
    #
    # @author Bill Claytor
    #
    # @param task [string] Task to run on nodes
    # @param params [hash] Task parameters to send to bolt
    # @param nodes [string] Host or space delimited hosts to run task on
    #
    # @return [true,false] Based on exit status of the bolt task
    def self.run_forge_task_with_bolt(task, params, nodes)
      install_forge_modules
      run_task_with_bolt(task, params, nodes, FORGE_MODULE_PATH)
    end

    # Run a plan from the forge with bolt on given nodes
    #
    # @author Bill Claytor
    #
    # @param plan [string] Plan to run on nodes
    # @param params [hash] Plan parameters to send to bolt
    # @param nodes [string] Host or space delimited hosts to run plan on
    #
    # @return [string] The output from the bolt run
    def self.run_forge_plan_with_bolt(plan, params, nodes)
      install_forge_modules
      run_plan_with_bolt(plan, params, nodes, FORGE_MODULE_PATH)
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
      command << bolt_options_string
      puts "Running: #{command}"
      output = `#{command}`
      puts "Output was: #{output}"

      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      raise "ERROR: failed to upload file #{source} to #{destination} on #{nodes}" unless success

      return success
    end

    # Install modules from the forge via Puppetfile
    #
    # @author Bill Claytor
    #
    # @return [true,false] Based on exit status of the bolt task
    def self.install_forge_modules
      command = "bolt puppetfile install --modulepath #{FORGE_MODULE_PATH}"
      puts "Running: #{command}"
      output = `#{command}`
      puts "Output was: #{output}"

      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      raise "ERROR: bolt command failed!" unless success

      return success
    end
  end
end
