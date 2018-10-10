require "optparse"

module RefArchSetup
  # Implements the command line subcommands
  #
  # @author Randell Pelak
  # @attr [hash] options Options from the command line
  class CLI
    # Initialize class
    #
    # @author Randell Pelak
    #
    # @param [Hash] options The options from the command line
    # @option options [String] something not yet defined
    #
    # @return [void]
    def initialize(options, bolt_options)
      @options = options
      @bolt_options = bolt_options
    end

    # Check values of options to see if they are really an option
    #
    # optparse will gobble up the next option if no value is given
    # This checks option values for things that start with --
    # and then assumes the user forgot to provide a value
    # This is okay as long as we don't need to support values with --
    #
    # @author Randell Pelak
    #
    # @raise [OptionParser::MissingArgument] Thrown if an option is missing and argument
    #
    # @example check_for_missing_value
    #
    # @return [void]
    def check_for_missing_value
      @options.each do |key, value|
        raise OptionParser::MissingArgument, key if value =~ /^--/
      end
    end

    # Checks for an option that is required by the sub command
    #
    # @author Randell Pelak
    #
    # @param [string] option the name of the option
    # @param [string] subcommand the name of the subcommand
    #
    # @example check_option("target_host", "install")
    #
    # @raise [OptionParser::MissingOption] Thrown if option is missing
    #
    # @return [void]
    def check_option(option, subcommand)
      return unless @options[option].nil? || @options[option].empty?
      option.tr!("_", "-")
      raise OptionParser::MissingOption, \
            "option --#{option} is required for the #{subcommand} subcommand"
    end

    # Wrapper around commands
    #
    # @author Randell Pelak
    #
    # @param [string] command the name of the command to run
    # @param [string] subcommand the name of the subcommand to run
    #
    # @return [boolean] success of install
    def run(command, subcommand = nil)
      check_for_missing_value
      BoltHelper.bolt_options = @bolt_options

      comm = command
      unless subcommand.nil?
        str = subcommand.tr("-", "_")
        comm += "_" + str
      end
      success = send(comm)
      return success
    end

    # Installs a bootstrap version of mono on the target host using the provided tarball and pe.conf
    #
    # @author Randell Pelak
    #
    # @return [boolean] success of install
    def install
      puts "Running install command"
      success = true
      success = install_generate_pe_conf unless @options.key?("pe_conf")
      # TODO: Pass pe.conf object along so we don't have to read/validate it in each subcommand
      success = install_bootstrap if success
      success = install_pe_infra_agent_install if success
      success = install_configure if success
      return success
    end

    # Generates a pe.conf for use doing the install
    #
    # @author Randell Pelak
    #
    # @return [boolean] success of generating the pe.conf file
    def install_generate_pe_conf
      puts "Running generate-pe-conf subcommand of install command"
      # check_option("console_password", "install") # password hardcoded in base file for now
      return true
    end

    # Installs a bootstrap version of PE on the target host using the provided tarball and pe.conf
    #
    # @author Randell Pelak
    #
    # @return [boolean] success of install
    def install_bootstrap
      puts "Running bootstrap subcommand of install command"
      # none of these will be required in the future...  but are for now
      check_option("primary_master", "install")
      check_option("pe_tarball", "install")
      install_obj = RefArchSetup::Install.new(@options["primary_master"])
      success = install_obj.bootstrap(@options["pe_conf"], @options["pe_tarball"])
      return success
    end

    # Installs an agent on infrastructure nodes
    #
    # @author Randell Pelak
    #
    # @return [boolean] success of agent install
    def install_pe_infra_agent_install
      puts "Running pe-infra-agent-install subcommand of install command"
      return true
    end

    # Configures infrastructure nodes and do initial perf tuning
    #
    # @author Randell Pelak
    #
    # @return [boolean] success of all the things
    def install_configure
      puts "Running configure subcommand of install command"
      return true
    end
  end
end

# from optparse
class OptionParser
  # Adds an exception for missing a required option
  #
  # OptionParser doesn't handle required options, only required arguments to the options
  # And even that it doesn't do all that well.
  # This creates a missing argument exception for use by this CLI class
  #
  # @author Randell Pelak
  class MissingOption < ParseError
    const_set(:Reason, "missing option".freeze)
  end
end
