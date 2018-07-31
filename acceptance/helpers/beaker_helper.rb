# Beaker helper methods for use in running acceptance tests
module BeakerHelper
  BEAKER_HOSTS = "#{__dir__}/../../hosts.cfg".freeze
  BEAKER_KEYFILE = "".freeze

  # Initializes the PE instance variables
  #
  # @author Bill Claytor
  #
  # @return [void]
  def initialize
    @pe_family = ENV["BEAKER_PE_FAMILY"] || "2018.2"
    @pe_url = "http://enterprise.delivery.puppetlabs.net/#{@pe_family}/ci-ready/LATEST"
    curl_comm = "curl --silent #{@pe_url}"
    @pe_version = ENV["BEAKER_PE_VERSION"] || `#{curl_comm}`.strip
  end

  # Creates a Beaker host file for the acceptance tests
  #
  # @author Bill Claytor
  #
  # @return [exit_code] The result of the host file creation
  #
  def beaker_create_host_file
    initialize

    forge_host = ENV["BEAKER_FORGE_HOST"] || "forge-aio01-petest.puppetlabs.com"
    hosts = "centos7-64controller.-64target_master_a.-64target_master_b.-64target_master_c."
    layout = ENV["BEAKER_LAYOUT"] || hosts

    comm = "export pe_version=#{@pe_version}; "
    comm += "bundle exec beaker-hostgenerator "
    comm += "--disable-default-role "
    comm += "--global-config forge_host=#{forge_host} "
    comm += layout
    comm += " > #{BEAKER_HOSTS}"

    puts "Creating Beaker hosts file:"

    sh comm
  end

  # Determines whether the hosts should be preserved at the end of the run
  #
  # @author Bill Claytor
  #
  # @return [true,false] Based on whether the hosts should be preserved
  def preserve_hosts?
    preserve = ENV["BEAKER_PRESERVE_HOSTS"]
    preserve == "always" ||
      ((@beaker_cmd.nil? || @beaker_cmd.result.exit_code != 0) &&
          preserve == "onfail")
  end

  # Ensures that the host file exists and creates the beaker init command
  #
  # @author Bill Claytor
  #
  # @param [task] task The current rake task
  #
  # @return [command] The Beaker command to execute
  #
  # rubocop:disable Metrics/MethodLength
  def beaker_init(task)
    beaker_create_host_file unless File.exist?(BEAKER_HOSTS)

    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker init"
      command.add_option do |option|
        option.name = "-h"
        option.add_argument do |arg|
          arg.name = BEAKER_HOSTS
        end
      end

      command.add_option do |option|
        option.name = "-o"
        option.add_argument do |arg|
          arg.name = "#{__dir__}/../config/options.rb"
        end
      end
    end

    return @beaker_cmd
  end
  # rubocop:enable Metrics/MethodLength

  # Creates the beaker provision command
  #
  # @author Bill Claytor
  #
  # @param [task] task The current rake task
  #
  # @return [command] The Beaker command to execute
  #
  def beaker_provision(task)
    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker provision"
    end

    return @beaker_cmd
  end

  # Creates the beaker exec command
  #
  # @author Bill Claytor
  #
  # @param [task] task The current rake task
  #
  # @return [command] The Beaker command to execute
  #
  # rubocop:disable Metrics/MethodLength
  def beaker_exec(task)
    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker exec"

      if ENV.key?("BEAKER_PRE_SUITE")
        command.add_option do |option|
          option.name = "--pre-suite"
          option.message = "Beaker pre-suite"
          option.add_argument do |arg|
            arg.add_env(name: "BEAKER_PRE_SUITE")
          end
        end

      end

      if ENV.key?("BEAKER_TESTS")
        command.add_option do |option|
          option.name = "--tests"
          option.message = "Beaker tests"
          option.add_argument do |arg|
            arg.add_env(name: "BEAKER_TESTS")
          end
        end

      end
    end

    return @beaker_cmd
  end
  # rubocop:enable Metrics/MethodLength

  # Creates the beaker destroy command
  #
  # @author Bill Claytor
  #
  # @param [task] task The current rake task
  #
  # @return [command] The Beaker command to execute
  #
  def beaker_destroy(task)
    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker destroy"
    end

    return @beaker_cmd
  end
end
