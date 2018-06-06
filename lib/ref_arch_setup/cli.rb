require "optparse"

module RefArchSetup
  # Implements the command line subcommands
  #
  # @author Randell Pelak
  # @attr [hash] options Options from the command line
  class CLI
    # initialize class
    #
    # @author Randell Pelak
    #
    # @param [Hash] options the options from the command line
    # @option options [String] something not yet defined
    #
    # @return [void]
    def initialize(options)
      @options = options
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

    # Installs a bootstrap version of mono on the target host using the provided tarball and pe.conf
    #
    # @author Randell Pelak
    #
    # @return [boolean] success of install
    def install
      check_for_missing_value
      check_option("target_host", "install")
      check_option("pe_tarball_path", "install")
      check_option("pe_conf_path", "install")
      install_obj = RefArchSetup::Install.new(@options["target_host"])
      success = install_obj.bootstrap_mono(@options["pe_tarball_path"], @options["pe_conf_path"])
      return success
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
