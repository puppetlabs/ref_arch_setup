require "fileutils"
require "rototiller"
require "yard"
require "rubocop/rake_task"
require "flog_task"
require "flay_task"
require "roodi_task"
require "rubycritic/rake_task"

YARD_DIR = "doc".freeze
DOCS_DIR = "docs".freeze

task :default do
  sh %(rake -T)
end

namespace :test do
  desc "Create hosts.cfg file"
  task :mk_hosts_file do
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
    comm += " > #{__dir__}/hosts.cfg"
    # puts comm.to_str
    sh comm
  end

  desc "Run acceptance test"
  rototiller_task :acceptance do |task|
    comm = add_beaker_command(task)
    puts comm.to_str
    comm.add_option do |option|
      option.name = "--options"
      option.add_argument do |arg|
        arg.name = "#{__dir__}/acceptance/config/options.rb"
      end
    end
    comm.add_option do |option|
      option.name = "--config"
      option.add_argument do |arg|
        arg.name = "#{__dir__}/hosts.cfg"
      end
    end
    puts comm.to_str
  end

  def add_beaker_command(task)
    # env vars needed for Beaker
    command = task.add_command do |command|
      command.name = "bundle exec beaker"
      command.add_env({:name => 'BEAKER_EXECUTABLE'})

      command.add_option do |option|
        option.name = '--hosts'
        option.message = 'The configuration file that Beaker will use'
        option.add_argument do |arg|
          arg.add_env({:name => 'BEAKER_HOSTS'})
        end
      end unless ( ! ENV.has_key?('BEAKER_HOSTS') )
      command.add_option do |option|
        option.name = '--keyfile'
        option.message = 'The SSH key used to access a SUT'
        option.add_argument do |arg|
          arg.add_env({:name => 'BEAKER_KEYFILE'})
        end
      end unless ( ! ENV.has_key?('BEAKER_KEYFILE') )
      command.add_option do |option|
        option.name = '--log-level'
        option.message = 'The log level under which you want beaker to run'
        option.add_argument do |arg|
          arg.add_env({:name => 'BEAKER_LOG_LEVEL'})
        end
      end unless ( ! ENV.has_key?('BEAKER_LOG_LEVEL') )
      unless ENV['BEAKER_PRE_SUITE'] == ''
        command.add_option do |option|
          option.name = '--pre-suite'
          option.message = 'Beaker pre-suite'
          option.add_argument do |arg|
            arg.add_env({:name => 'BEAKER_PRE_SUITE'})
          end
        end
      end unless ( ! ENV.has_key?('BEAKER_PRE_SUITE') )
      unless ENV['HELPER_PATH'] == ''
        command.add_option do |option|
          option.name = '--helper'
          option.message = 'Setup helper required for installing PE'
          option.add_argument do |arg|
            arg.add_env({:name => 'BEAKER_HELPER'})
          end
        end
      end unless ( ! ENV.has_key?('BEAKER_HELPER') )
      command.add_option do |option|
        option.name = '--preserve-hosts'
        option.message = 'Whether to preserve hosts or not'
        option.add_argument do |arg|
          arg.add_env({:name => 'BEAKER_PRESERVE_HOSTS'})
        end
      end unless ( ! ENV.has_key?('BEAKER_PRESERVE_HOSTS') )
      command.add_option do |option|
        option.name = '--type'
        option.message = 'pe or foss'
        option.add_argument do |arg|
          arg.add_env({:name => 'BEAKER_INSTALL_TYPE'})
        end
      end unless ( ! ENV.has_key?('BEAKER_INSTALL_TYPE') )
    end
    return command
  end
end

# bunch of gem build, clean, install, release tasks
namespace :gem do
  require "bundler/gem_tasks"
end

# various yarddoc docs tasks
#   arch, clean, measure, undoc, verify, yard
# rubocop:disable Metrics/BlockLength
namespace :docs do
  # docs:yard task
  YARD::Rake::YardocTask.new

  desc "Clean/remove the generated YARD Documentation cache"
  task :clean do
    original_dir = Dir.pwd
    Dir.chdir(File.expand_path(__dir__))
    sh "rm -rf #{YARD_DIR}"
    Dir.chdir(original_dir)
  end

  desc "Tell me about YARD undocumented objects"
  YARD::Rake::YardocTask.new(:undoc) do |t|
    t.stats_options = ["--list-undoc"]
  end

  desc "Measure YARD coverage"
  require "yardstick/rake/measurement"
  options = YAML.load_file(".yardstick.yml")
  Yardstick::Rake::Measurement.new(:measure, options) do |measurement|
    measurement.output = "yardstick/report.txt"
  end

  desc "Verify YARD coverage"
  require "yardstick/rake/verify"
  config = { "require_exact_threshold" => false }
  Yardstick::Rake::Verify.new(:verify, config) do |verify|
    verify.threshold = 80
  end

  desc "Generate static project architecture graph. (Calls docs:yard)"
  # this calls `yard graph` so we can't use the yardoc tasks like above
  #   We could create a YARD:CLI:Graph object.
  #   But we still have to send the output to the graphviz processor, etc.
  task arch: [:yard] do
    original_dir = Dir.pwd
    Dir.chdir(File.expand_path(__dir__))
    graph_processor = "dot"
    if exe_exists?(graph_processor)
      FileUtils.mkdir_p(DOCS_DIR)
      if system("yard graph --full | #{graph_processor} -Tpng " \
          "-o #{DOCS_DIR}/arch_graph.png")
        puts "we made you a class diagram: #{DOCS_DIR}/arch_graph.png"
      end
    else
      puts "ERROR: you don't have dot/graphviz; punting"
    end
    Dir.chdir(original_dir)
  end
end

task :test do
  Rake::Task["test:spec"].invoke
end

namespace :test do
  desc "check number of lines of code changed. To protect against long PRs"
  task "diff_length" do
    max_length = 150
    target_branch = ENV["DISTELLI_RELBRANCH"] || "master"
    diff_cmd = "git diff --numstat #{target_branch}"
    sum_cmd  = "awk '{s+=$1} END {print s}'"
    cmd      = "[ `#{diff_cmd} | #{sum_cmd}` -lt #{max_length} ]"
    puts "checking if diff length is less than #{max_length} LoC"
    exit system(cmd)
  end

  # this will produce the 'test:rubocop','test:rubocop:auto_correct' tasks
  RuboCop::RakeTask.new do |task|
    task.options = ["--debug"]
  end

  # this will produce the 'test:flog' task
  allowed_complexity = 585 # <cough!>
  FlogTask.new :flog, allowed_complexity, %w[lib]
  # this will produce the 'test:flay' task
  allowed_repitition = 0
  FlayTask.new :flay, allowed_repitition, %w[lib]
  # this will produce the 'test:roodi' task
  RoodiTask.new
  # this will produce the 'test:rubycritic' task
  RubyCritic::RakeTask.new do |task|
    task.paths   = FileList["lib/**/*.rb"]
  end

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
