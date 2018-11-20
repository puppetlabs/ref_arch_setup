require "beaker"

# Helper methods for use in running Beaker acceptance tests
# rubocop:disable Metrics/ModuleLength
module BeakerHelper
  BEAKER_HOSTS = "#{__dir__}/../../hosts.cfg".freeze
  LAYOUT = ENV["BEAKER_LAYOUT"] || "centos7-64controller.-64target_master.".freeze
  FORGE_HOST = ENV["BEAKER_FORGE_HOST"] || "forge-aio01-petest.puppetlabs.com".freeze
  PE_TARBALL_EXTENSION = ENV["BEAKER_PE_TARBALL_EXTENSION"] || ".tar".freeze
  BEAKER_RAS_PATH = "$HOME/ref_arch_setup".freeze
  BEAKER_RAS_FIXTURES_PATH = "#{BEAKER_RAS_PATH}/fixtures".freeze
  BEAKER_RAS_MODULES_PATH = "#{BEAKER_RAS_PATH}/modules".freeze
  BEAKER_RAS_PE_CONF = "#{BEAKER_RAS_FIXTURES_PATH}/pe.conf".freeze
  RAS_TMP_WORK_DIR = "/tmp/ref_arch_setup".freeze

  BEAKER_DOCKER_HOSTS = "docker_hosts.cfg".freeze

  # Initializes the PE instance variables
  #
  # @author Bill Claytor
  #
  # @return [void]
  def beaker_initialize
    pe_family = ENV["BEAKER_PE_FAMILY"] || "2019.0"
    pe_url = "http://enterprise.delivery.puppetlabs.net/#{pe_family}/ci-ready/LATEST"
    curl_comm = "curl --silent #{pe_url}"
    @pe_version = ENV["BEAKER_PE_VERSION"] || `#{curl_comm}`.strip

    @beaker_hosts = if ENV["BEAKER_HOSTS"] && File.exist?(ENV["BEAKER_HOSTS"])
                      ENV["BEAKER_HOSTS"]
                    else
                      BEAKER_HOSTS
                    end

    @beaker_docker_hosts = ENV["BEAKER_DOCKER_HOSTS"] || BEAKER_DOCKER_HOSTS
  end

  # Creates a Beaker host file for the acceptance tests
  #
  # @author Bill Claytor
  #
  # @return [exit_code] The result of the host file creation
  #
  def beaker_create_host_file
    # forge_host = ENV["BEAKER_FORGE_HOST"] || "forge-aio01-petest.puppetlabs.com"
    # hosts = "centos7-64controller.-64target_master."
    # layout = ENV["BEAKER_LAYOUT"] || hosts
    comm = "export pe_version=#{@pe_version}; "
    comm += "bundle exec beaker-hostgenerator "
    comm += "--disable-default-role "
    comm += "--global-config forge_host=#{FORGE_HOST} "
    comm += LAYOUT
    comm += " > #{@beaker_hosts}"

    puts "Creating Beaker hosts file: #{@beaker_hosts}"
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
    # TODO: config
    beaker_create_host_file unless File.exist?(@beaker_hosts)

    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker init"
      command.add_option do |option|
        option.name = "-h"
        option.add_argument do |arg|
          arg.name = @beaker_hosts
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

  # Creates the beaker init command for the docker tests
  #
  # @author Bill Claytor
  #
  # @param [task] task The current rake task
  #
  # @return [command] The Beaker command to execute
  #
  # rubocop:disable Metrics/MethodLength
  def beaker_docker_init(task)
    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker init"
      command.add_option do |option|
        option.name = "-h"
        option.add_argument do |arg|
          arg.name = @beaker_docker_hosts
        end
      end

      command.add_option do |option|
        option.name = "-o"
        option.add_argument do |arg|
          arg.name = "acceptance/config/docker_options.rb"
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

  # Builds a PE tarball URL for the specified host
  #
  # The host must include a pe_dir, pe_ver, and platform
  #
  # Extracted from pe_utils.fetch_pe_on_unix
  #   assumes being called by beaker with a host (master)
  #   this version is simplified by removing the call to prepare_ras_host
  #
  # @param [Host] host The unix style host where PE will be installed
  # @return [String] the tarball URL
  # @example
  #   url = get_pe_tarball_url(host)
  #
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def get_pe_tarball_url(host)
    raise "The host must include a pe_dir value" unless host["pe_dir"]
    raise "The host must include a pe_ver value" unless host["pe_ver"]
    raise "The host must include a platform value" unless host["platform"]

    path = host["pe_dir"]
    version = host["pe_ver"]
    platform = host["platform"]
    filename = "puppet-enterprise-#{version}-#{platform}"

    url = "#{path}/#{filename}#{PE_TARBALL_EXTENSION}"

    puts "Determining tarball path for host: #{host}"
    puts "pe_dir: #{path}"
    puts "pe_ver: #{version}"
    puts "platform: #{platform}"
    puts
    puts "PE tarball URL: #{url}"
    puts

    raise "The URL is not a valid link: #{url}" unless link_exists?(url)

    return url
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # Builds a PE tarball filename for the specified host
  #
  # The host must include a pe_ver and platform
  #
  # @param [Host] host The unix style host where PE will be installed
  # @return [String] the tarball filename
  # @example
  #   filename = get_pe_tarball_filename(host)
  #
  def get_pe_tarball_filename(host)
    raise "host must include a pe_ver value" unless host["pe_ver"]
    raise "host must include a platform value" unless host["platform"]

    version = host["pe_ver"]
    platform = host["platform"]
    filename = "puppet-enterprise-#{version}-#{platform}#{PE_TARBALL_EXTENSION}"

    return filename
  end

  # Gets the path to the installed RAS gem on the specified host
  #
  # @param [Host] host A unix style host
  # @example
  #   gem_path = get_ras_gem_path(host)
  #
  def get_ras_gem_path(host)
    command = "gem path ref_arch_setup"
    gem_path = on(host, command).stdout.rstrip
    puts "RAS gem path: #{gem_path}"
    gem_path
  end

  # Uninstalls puppet and removes the RAS working dir on the specified hosts
  #
  # @param [Array] hosts The unix style hosts where teardown should be run
  # @example
  #   ras_teardown(hosts)
  #
  def ras_teardown(hosts)
    puts "Tearing down the following hosts:"
    puts hosts
    puts

    ras_teardown_uninstall_puppet(hosts)
    ras_teardown_remove_temp(hosts)
  end

  # Removes the RAS working dir on the specified hosts
  #
  # @param [Array] hosts The unix style hosts where teardown should be run
  # @example
  #   ras_docker_teardown(hosts)
  #
  def ras_docker_teardown(hosts)
    puts "Tearing down the following hosts:"
    puts hosts
    puts

    ras_teardown_remove_temp(hosts)
  end

  # Uninstalls puppet on the specified hosts
  #
  # @param [Array] hosts The unix style hosts where teardown should be run
  # @example
  #   ras_teardown_uninstall_puppet(hosts)
  #
  def ras_teardown_uninstall_puppet(hosts)
    # TODO: make this a task
    command = "cd /opt/puppetlabs/bin/ && ./puppet-enterprise-uninstaller -d -p -y"

    puts "Uninstalling puppet:"
    puts command
    puts
    on hosts, command
  end

  # Removes the RAS working dir on the specified hosts
  #
  # @param [Array] hosts The unix style hosts where teardown should be run
  # @example
  #   ras_teardown_remove_temp(hosts)
  #
  def ras_teardown_remove_temp(hosts)
    command = "rm -rf #{RAS_TMP_WORK_DIR}"

    puts "Removing temp work directory:"
    puts command
    puts
    on hosts, command
  end

  # Returns all hosts except those with the specified role
  #
  # @param [Array] hosts The unix style hosts
  # @example
  #   hosts_except_controller = hosts_without_role(hosts, "controller")
  #
  def hosts_without_role(hosts, role_to_exclude)
    hosts.select do |host|
      host unless host["roles"].include?(role_to_exclude.to_s)
    end
  end

  # Runs the mock puppet agent on the specified host
  #
  # @param host The unix style host
  #
  # @example
  #   output = run_mock_puppet_agent(host)
  #
  def run_mock_puppet_agent(host)
    fake_puppet_path = "/tmp/ref_arch_setup/puppet-enterprise-*"
    command = "#{fake_puppet_path}/puppet agent -t"

    output = on(host, command).stdout.rstrip
    return output
  end
end

Beaker::TestCase.send(:include, BeakerHelper)
Beaker::TestCase.class_eval { include Beaker::DSL }
