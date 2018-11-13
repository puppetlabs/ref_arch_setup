# General namespace for RAS
module RefArchSetup
  # Bolt helper methods
  class BoltHelper
    # the user RAS will provide to the bolt --run-as option
    BOLT_RUN_AS_USER = "root".freeze

    # the default options to specify when running bolt commands
    BOLT_DEFAULT_OPTIONS = { "run-as" => BOLT_RUN_AS_USER, "no-host-key-check" => "" }.freeze

    @bolt_options = BOLT_DEFAULT_OPTIONS

    # custom exception class for bolt command errors
    class BoltCommandError < StandardError
      attr_reader :output
      def initialize(message, output)
        @output = output
        super(message)
      end
    end

    # Initializes the bolt options to the default
    #
    # @author Bill Claytor
    #
    def self.init
      @bolt_options = BOLT_DEFAULT_OPTIONS
    end

    # Merges the specified bolt options with the default options
    # or optionally overwriting the default options
    #
    # @author Bill Claytor
    #
    # @param [hash] options_hash The user-specified bolt options hash
    # @param [boolean] overwrite The flag indicating whether the default options
    #   should be overwritten
    #
    def self.bolt_options(options_hash, overwrite = false)
      @bolt_options = if overwrite
                        options_hash
                      else
                        @bolt_options.merge(options_hash)
                      end
    end

    # Merges the default bolt options with the specified options
    #
    # @author Bill Claytor
    #
    # @param [hash] options_hash The user-specified bolt options hash
    #
    def self.bolt_options=(options_hash)
      bolt_options(options_hash)
    end

    # Gets the bolt options as a string
    #
    # @author Sam Woods
    # @return [string] the string value for bolt options
    def self.bolt_options_string
      bolt_options_string = ""
      @bolt_options.each do |key, value|
        # options like no-host-key-check don't have a value
        bolt_options_string << if value.empty?
                                 " --#{key}"
                               else
                                 " --#{key} #{value}"
                               end
      end
      bolt_options_string
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
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [true,false] Based on the output returned from the bolt command
    def self.make_dir(dir, nodes)
      error_message = "ERROR: Failed to make dir #{dir} on all nodes"
      cmd = "mkdir -p #{dir}"
      output = run_cmd_with_bolt(cmd, nodes, error_message)
      success = output.nil? ? false : true
      return success
    end

    # Run the specified command
    #
    # @author Bill Claytor
    #
    # @param command [string] The command to run
    # @param error_message [string] The error to raise if the command is not successful
    #
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [string] The output returned from the command
    def self.run_command(command, error_message = "ERROR: command failed!")
      puts "Running: #{command}"
      output = `#{command}`
      puts "Output was: #{output}"

      success = $?.success? # rubocop:disable Style/SpecialGlobalVars
      puts "Exit status was: #{$?.exitstatus}" # rubocop:disable Style/SpecialGlobalVars
      puts

      # raise error_message unless success
      raise BoltCommandError.new(error_message, output) if output.nil?
      raise BoltCommandError.new(error_message, output) unless success

      return output
    end

    # Run a command with bolt on given nodes
    #
    # @author Randell Pelak
    #
    # @param [string] cmd Command to run on the specified nodes
    # @param [string] nodes Nodes on which the command should be run
    # @param [string] error_message The message that should be used if an error is raised
    #
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [string] The output returned from the bolt command
    def self.run_cmd_with_bolt(cmd, nodes, error_message = "ERROR: bolt command failed!")
      command = "bolt command run '#{cmd}'"
      command << " --nodes #{nodes}"
      command << bolt_options_string

      output = run_command(command, error_message)
      return output
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
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [string] The output returned from the bolt command
    def self.run_task_with_bolt(task, params, nodes, modulepath = RAS_MODULE_PATH)
      params_str = ""
      params_str = params_to_string(params) unless params.nil?
      command = "bolt task run #{task} #{params_str}"
      command << " --modulepath #{modulepath} --nodes #{nodes}"
      command << bolt_options_string

      output = run_command(command, "ERROR: bolt task failed!")
      return output
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
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [string] The output returned from the bolt command
    def self.run_plan_with_bolt(plan, params, nodes, modulepath = RAS_MODULE_PATH)
      params_str = ""
      params_str = params_to_string(params) unless params.nil?
      command = "bolt plan run #{plan} #{params_str}"
      command << " --modulepath #{modulepath} --nodes #{nodes}"
      command << bolt_options_string

      output = run_command(command, "ERROR: bolt plan failed!")
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
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [string] The output returned from the bolt command
    def self.run_forge_task_with_bolt(task, params, nodes)
      install_forge_modules
      output = run_task_with_bolt(task, params, nodes, FORGE_MODULE_PATH)
      return output
    end

    # Run a plan from the forge with bolt on given nodes
    #
    # @author Bill Claytor
    #
    # @param plan [string] Plan to run on nodes
    # @param params [hash] Plan parameters to send to bolt
    # @param nodes [string] Host or space delimited hosts to run plan on
    #
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [string] The output returned from the bolt command
    def self.run_forge_plan_with_bolt(plan, params, nodes)
      install_forge_modules
      output = run_plan_with_bolt(plan, params, nodes, FORGE_MODULE_PATH)
      return output
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
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [output] The output returned from the bolt command
    def self.upload_file(source, destination, nodes)
      command = "bolt file upload #{source} #{destination}"
      command << " --nodes #{nodes}"
      command << bolt_options_string

      error_message = "ERROR: failed to upload file #{source} to #{destination} on #{nodes}"
      output = run_command(command, error_message)
      return output
    end

    # Install modules from the forge via Puppetfile
    # The modules are defined in Boltdir/Puppetfile
    #
    # @author Bill Claytor
    #
    # @raise [BoltCommandError] If the bolt command is not successful or the output is nil
    #
    # @return [string] The output returned from the bolt command
    def self.install_forge_modules
      command = "cd #{RAS_PATH} && bolt puppetfile install --modulepath #{FORGE_MODULE_PATH}"
      output = run_command(command, "ERROR: bolt puppetfile install failed!")
      return output
    end
  end
end
