require "yard"
require "fileutils"
require "rototiller"
require "./gem_of/lib/gem_of/rake_tasks"
require "./acceptance/helpers/beaker_helper"
require "./lib/ref_arch_setup.rb"

include BeakerHelper

# Yardstick tasks using the config in .yardstick.yml
# Note: this is currently required to include folders other than lib
# TODO: remove this if gem_of is updated to use yardstick.yml
class RasYardStickTasks
  include Rake::DSL if defined? Rake::DSL
  # add ras yardstick tasks to namespace :docs
  #
  # @example YardStackTasks.new
  # rubocop:disable Metrics/MethodLength
  def initialize
    namespace :docs do
      config = YAML.load_file(".yardstick.yml")

      desc "Measure YARD coverage. see yardstick/report.txt for output"
      require "yardstick/rake/measurement"
      Yardstick::Rake::Measurement.new(:measure_ras, config) do |measurement|
        measurement.output = "yardstick/ras_report.txt"
      end

      task measure_ras: [:measure_ras_message] # another way to force a dependent task
      desc "" # empty description so this doesn't show up in rake -T
      task :measure_ras_message do
        puts "creating a report in yardstick/ras_report.txt"
      end

      desc "Verify YARD coverage"
      require "yardstick/rake/verify"
      Yardstick::Rake::Verify.new(:verify_ras, config)
    end
  end
end

YARD_DIR = "doc".freeze
DOCS_DIR = "docs".freeze

task :default do
  sh %(rake -T)
end

GemOf::GemTasks.new
GemOf::YardStickTasks.new
GemOf::DocsTasks.new
GemOf::LintTasks.new

RasYardStickTasks.new

namespace :bolt do
  desc "Install modules from the forge via Puppetfile"
  task :install_forge_modules do
    RefArchSetup::BoltHelper.install_forge_modules
  end

  desc "Run the facts::retrieve plan locally"
  task :facts do
    RefArchSetup::BoltHelper.run_forge_plan_with_bolt("facts::retrieve", nil, "localhost")
  end
end

namespace :pr do
  desc "Run the docs, lint, and test tasks for pull requests"
  task :check do
    puts "Running RAS PR checks"

    ENV["SPEC_PATTERN"] = "spec/ref_arch_setup/*_spec.rb"
    Rake::Task["docs:measure_ras"].execute
    Rake::Task["docs:ras_report"].execute
    Rake::Task["docs:verify_ras"].execute
    Rake::Task["lint:rubocop"].execute
    Rake::Task["test:spec"].execute
    # Rake::Task["test:acceptance_docker"].execute
  end
end

namespace :docs do
  desc "Display the yardstick/ras_report.txt file"
  task :ras_report do
    ras_report = "./yardstick/ras_report.txt"
    raise "Unable to locate report: #{ras_report}" unless File.exist?(ras_report)

    puts "Reading report from yardstick/ras_report.txt"
    puts
    puts "Yardstick Coverage Report"

    # File.open("./yardstick/ras_report.txt").readlines.each do |line|
    #   puts line
    # end

    sh %(cat ./yardstick/ras_report.txt)

    puts
  end
end

# rubocop:disable Metrics/BlockLength
namespace :test do
  desc "Create hosts.cfg file"
  task :mk_hosts_file do
    beaker_initialize
    beaker_create_host_file
  end

  desc "Run acceptance test suite using Beaker subcommands"
  task :acceptance do
    beaker_initialize
    Rake::Task["gem:build"].execute
    Rake::Task["test:acceptance_init"].execute
    Rake::Task["test:acceptance_provision"].execute
    Rake::Task["test:acceptance_exec"].execute
    Rake::Task["test:acceptance_destroy"].execute unless preserve_hosts?
  end

  desc "Run the acceptance pre-suite"
  task :acceptance_pre_suite do
    ENV["BEAKER_TESTS"] = "acceptance/tests/00_nothing.rb"
    ENV["BEAKER_PRESERVE_HOSTS"] = "always"
    Rake::Task["test:acceptance"].execute
  end

  desc "Run the demo setup from the acceptance pre-suite"
  task :acceptance_setup_ras_demo do
    ENV["BEAKER_PRE_SUITE"] = "acceptance/pre_suites/10_setup_ssh.rb,"\
                              "acceptance/pre_suites/20_install_rbenv.rb,"\
                              "acceptance/pre_suites/25_install_gems.rb,"\
                              "acceptance/pre_suites/90_setup_ras_demo.rb,"\
                              "acceptance/pre_suites/99_output_host_info.rb"

    Rake::Task["test:acceptance_pre_suite"].execute
  end

  desc "Run the docker demo setup from the acceptance pre-suite"
  task :acceptance_setup_ras_docker_demo do
    ENV["BEAKER_PRE_SUITE"] = "acceptance/pre_suites/10_setup_ssh.rb,"\
                              "acceptance/pre_suites/91_setup_docker.rb,"\
                              "acceptance/pre_suites/99_output_host_info.rb"

    Rake::Task["test:acceptance_pre_suite"].execute
  end

  desc "Run init subcommand"
  rototiller_task :acceptance_init do |task|
    beaker_init(task)
  end

  desc "Run provision subcommand"
  rototiller_task :acceptance_provision do |task|
    beaker_provision(task)
  end

  desc "Run exec subcommand"
  rototiller_task :acceptance_exec do |task|
    beaker_exec(task)
  end

  desc "Run destroy subcommand"
  rototiller_task :acceptance_destroy do |task|
    beaker_destroy(task)
  end

  desc "Run acceptance docker test suite"
  task :acceptance_docker do
    beaker_initialize
    Rake::Task["gem:build"].execute
    Rake::Task["test:acceptance_docker_init"].execute
    Rake::Task["test:acceptance_exec"].execute
    Rake::Task["test:acceptance_destroy"].execute unless preserve_hosts?
  end

  desc "Run acceptance docker init subcommand"
  rototiller_task :acceptance_docker_init do |task|
    beaker_docker_init(task)
  end
end
# rubocop:enable Metrics/BlockLength

namespace :test do
  begin
    # this will produce the 'test:spec' task
    require "rspec/core/rake_task"
    desc "Run unit tests"
    RSpec::Core::RakeTask.new do |t|
      t.rspec_opts = ["--color"]
      t.pattern = ENV["SPEC_PATTERN"]
    end
  # if rspec isn't available, we can still use this Rakefile
  # rubocop:disable Lint/HandleExceptions
  rescue LoadError
  end

  task spec: [:check_spec]

  desc "" # empty description so it doesn't show up in rake -T
  rototiller_task :check_spec do |t|
    t.add_env(name: "SPEC_PATTERN", default: "**{,/*/**}/*_spec.rb",
              message: "The pattern RSpec will use to find tests")
  end
end

task :test do
  Rake::Task["test:spec"].invoke
end

# Cross-platform exe_exists?
def exe_exists?(name)
  exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(";") : [""]
  ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
    exts.each do |ext|
      exe = File.join(path, "#{name}#{ext}")
      return true if File.executable?(exe) && !File.directory?(exe)
    end
  end
  false
end
