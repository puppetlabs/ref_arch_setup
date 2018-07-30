

module BeakerHelper
  BEAKER_HOSTS = "hosts.cfg".freeze
  BEAKER_KEYFILE = "".freeze

  def beaker_create_host_file
    pe_family = ENV["BEAKER_PE_FAMILY"] || "2018.2"
    url = "http://enterprise.delivery.puppetlabs.net/#{pe_family}/ci-ready/LATEST"
    curl_comm = "curl --silent #{url}"
    pe_version = ENV["BEAKER_PE_VERSION"] || `#{curl_comm}`.strip
    forge_host = ENV["BEAKER_FORGE_HOST"] || "forge-aio01-petest.puppetlabs.com"
    layout = ENV["BEAKER_LAYOUT"] || "centos7-64controller.-64target_master."
    comm = "export pe_version=#{pe_version}; "
    comm += "bundle exec beaker-hostgenerator "
    comm += "--disable-default-role "
    comm += "--global-config forge_host=#{forge_host} "
    comm += layout
    comm += " > #{__dir__}/#{BEAKER_HOSTS}"
    # puts comm.to_str
    sh comm
  end

  # TODO: update to return if file exists
  def beaker_ensure_host_file
    beaker_create_host_file
  end

  def preserve_hosts?
    preserve = ENV["BEAKER_PRESERVE_HOSTS"]
    preserve == "always" ||
      ((@beaker_cmd.nil? || @beaker_cmd.result.exit_code != 0) &&
          preserve == "onfail")
  end

  def beaker_init(task)
    beaker_ensure_host_file

    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker init"
      # command.add_env(name: "BEAKER_EXECUTABLE")

      command.add_option do |option|
        option.name = "-h"
        option.add_argument do |arg|
          arg.name = "#{__dir__}/../../hosts.cfg"
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

  def beaker_provision(task)
    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker provision"
    end

    return @beaker_cmd
  end

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

  def beaker_destroy(task)
    @beaker_cmd = task.add_command do |command|
      command.name = "bundle exec beaker destroy"
    end

    return @beaker_cmd
  end
end
