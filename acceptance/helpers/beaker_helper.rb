require "beaker"

# Helper methods for use in running Beaker acceptance tests
# rubocop:disable Metrics/ModuleLength
module BeakerHelper
  # the bolt version to install for testing
  RAS_BOLT_VERSION = "1.5.0".freeze

  # the bolt package name
  RAS_BOLT_PKG = "puppet-bolt-#{RAS_BOLT_VERSION}".freeze

  # the bolt bin dir
  BOLT_BIN_DIR = "/opt/puppetlabs/bolt/bin".freeze

  # the beaker hosts file
  BEAKER_HOSTS = "#{__dir__}/../../hosts.cfg".freeze

  # the beaker layout
  LAYOUT = ENV["BEAKER_LAYOUT"] || "centos7-64controller.-64target_master.".freeze

  # the forge host
  FORGE_HOST = ENV["BEAKER_FORGE_HOST"] || "forge-aio01-petest.puppetlabs.com".freeze

  # the pe tarball extension
  PE_TARBALL_EXTENSION = ENV["BEAKER_PE_TARBALL_EXTENSION"] || ".tar".freeze

  # the ref_arch_setup path on the beaker host
  BEAKER_RAS_PATH = "$HOME/ref_arch_setup".freeze

  # the ref_arch_setup/fixtures path on the beaker host
  BEAKER_RAS_FIXTURES_PATH = "#{BEAKER_RAS_PATH}/fixtures".freeze

  # the ref_arch_setup/modules path on the beaker host
  BEAKER_RAS_MODULES_PATH = "#{BEAKER_RAS_PATH}/modules".freeze

  # the pe.conf path on the beaker host
  BEAKER_RAS_PE_CONF = "#{BEAKER_RAS_FIXTURES_PATH}/pe.conf".freeze

  # the RAS temporary working directory
  RAS_TMP_WORK_DIR = "/tmp/ref_arch_setup".freeze

  # the beaker hosts file used in the docker acceptance tests
  BEAKER_DOCKER_HOSTS = "docker_hosts.cfg".freeze

  # Initializes the PE instance variables
  #
  # @author Bill Claytor
  #
  # @return [void]
  #
  # @example
  #   beaker_initialize
  #
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
  # @example
  #   beaker_create_host_file
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
  #
  # @example
  #   result = preserve_hosts?
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
  # @example
  #   command = beaker_init(task)
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
  # @example
  #  command = beaker_docker_init(task)
  #
  # rubocop:disable Metrics/MethodLength
  #
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
  # @example
  #   command = beaker_provision(task)
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
  # @example
  #   command = beaker_exec(task)
  #
  # rubocop:disable Metrics/BlockLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def beaker_exec(task)
    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker exec"

      command.add_option do |option|
        option.name = "--log-level"
        option.message = "The log level under which you want beaker to run"
        option.add_argument do |arg|
          arg.name = "verbose"
          arg.add_env(name: "BEAKER_LOG_LEVEL")
        end
      end

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
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/BlockLength

  # Creates the beaker destroy command
  #
  # @author Bill Claytor
  #
  # @param [task] task The current rake task
  #
  # @return [command] The Beaker command to execute
  #
  # @example
  #   command = beaker_destroy(task)
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
  #
  # @return [String] The tarball URL
  #
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
  #
  # @return [String] The tarball filename
  #
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
  #
  # @return [String] The ref_arch_setup gem path
  #
  # @example
  #   gem_path = get_ras_gem_path(host)
  #
  def get_ras_gem_path(host)
    command = "#{BOLT_BIN_DIR}/gem path ref_arch_setup"
    gem_path = on(host, command).stdout.rstrip
    puts "RAS gem path: #{gem_path}"
    gem_path
  end

  # Uninstalls puppet and removes the RAS working dir on the specified host
  #
  # @param [Array] host The unix style host where teardown should be run
  #
  # @return [String] The tarball URL
  #
  # @example
  #   ras_teardown(host)
  #
  def ras_teardown(host)
    puts "Tearing down the following host:"
    puts hosts
    puts

    ras_teardown_uninstall_puppet(host)
    ras_teardown_remove_temp(host)

    return unless hosts_with_role(hosts, "controller").include?(host)
    # currently uninstalling puppet will remove the bolt install
    # but rpm will still think it is installed.
    # So have to uninstall and reinstall.
    # The installer team is fixing this PE-25441
    # TODO remove after PE-25441 is merged and released
    remove_bolt_pkg(host)
    install_bolt_pkg(host)
    install_ras_gem(host)
  end

  # Removes the RAS working dir on the specified host
  #
  # @param [Array] host The unix style host where teardown should be run
  #
  # @return [void]
  #
  # @example
  #   ras_docker_teardown(host)
  #
  def ras_docker_teardown(host)
    puts "Tearing down the following host:"
    puts host
    puts

    ras_teardown_remove_temp(host)
  end

  # Uninstalls puppet on the specified host
  #
  # @param [Array] host The unix style host where teardown should be run
  #
  # @return [void]
  #
  # @example
  #   ras_teardown_uninstall_puppet(host)
  #
  def ras_teardown_uninstall_puppet(host)
    # TODO: make this a task
    command = "cd /opt/puppetlabs/bin/ && ./puppet-enterprise-uninstaller -d -p -y"

    puts "Uninstalling puppet:"
    puts command
    puts
    on host, command
  end

  # Removes the RAS working dir on the specified host
  #
  # @param [Array] host The unix style hosts where teardown should be run
  #
  # @return [void]
  #
  # @example
  #   ras_teardown_remove_temp(host)
  #
  def ras_teardown_remove_temp(host)
    command = "rm -rf #{RAS_TMP_WORK_DIR}"

    puts "Removing temp work directory:"
    puts command
    puts
    on host, command
  end

  # Removed the bolt pkg from the host
  # This is needed because puppet uninstall removes the bolt code,
  # but rpm thinks it is still installed
  # The installer team is fixing this PE-25441
  # TODO remove after PE-25441 is merged and released
  #
  # @param [Host] host A unix style host
  #
  # @return [void]
  #
  # @example
  #   remove_bolt_pkg(host)
  #
  def install_bolt_repo(host)
    command = "rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm"
    puts command
    on host, command
  end

  # Removed the bolt pkg from the host
  # This is needed because puppet uninstall removes the bolt code,
  # but rpm thinks it is still installed
  # The installer team is fixing this PE-25441
  # TODO remove after PE-25441 is merged and released
  #
  # @param [Host] host A unix style host
  #
  # @return [void]
  #
  # @example
  #   remove_bolt_pkg(host)
  #
  def remove_bolt_pkg(host)
    command = "rpm -e --quiet #{RAS_BOLT_PKG}"
    puts command
    on host, command
  end

  # Install the bolt pkg on the host
  # This is needed because puppet uninstall removes the bolt code,
  # but rpm thinks it is still installed, so we must uninstall and reinstall
  # The installer team is fixing this PE-25441
  # TODO remove after PE-25441 is merged and released
  #
  # @param [Host] host A unix style host
  #
  # @return [void]
  #
  # @example
  #   install_bolt_pkg(host)
  #
  def install_bolt_pkg(host)
    command = "yum install -y #{RAS_BOLT_PKG}"
    puts command
    on host, command
  end

  # Install ras on the host using the bolt gem
  # This is needed because puppet uninstall removes the bolt code,
  # but rpm thinks it is still installed, so we must uninstall and reinstall
  # The installer team is fixing this PE-25441
  # TODO remove after PE-25441 is merged and released
  #
  # @param [Host] host A unix style host
  #
  # @return [void]
  #
  # @example
  #   install_ras_gem(host)
  #
  def install_ras_gem(host)
    version = RefArchSetup::Version::STRING
    gem = "ref_arch_setup-#{version}.gem"
    command = "#{BOLT_BIN_DIR}/gem install #{BEAKER_RAS_PATH}/#{gem}"
    puts command
    on host, command
  end

  # Returns all hosts except those with the specified role
  #
  # @param [Array] hosts The unix style hosts
  #
  # @return [Array] The hosts without the specified role
  #
  # @example
  #   hosts_except_controller = hosts_without_role(hosts, "controller")
  #
  def hosts_without_role(hosts, role_to_exclude)
    hosts.select do |host|
      host unless host["roles"].include?(role_to_exclude.to_s)
    end
  end
end

Beaker::TestCase.send(:include, BeakerHelper)
Beaker::TestCase.class_eval { include Beaker::DSL }
