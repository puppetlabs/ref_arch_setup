# rubocop:disable Metrics/BlockLength
test_name "perform install on remote master with tarball url" do
  step "perform install" do
    # TODO: use URL from BoltHelper
    pe_version = "puppet-enterprise-2018.1.0-rc14-el-7-x86_64"
    pe_dir = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1"
    pe_url = "#{pe_dir}/#{pe_version}.tar.gz"
    primary_master = "--primary-master=#{target_master}"
    pe_tarball = "--pe-tarball=#{pe_url}"
    pe_conf = "--pe-conf=/root/ref_arch_setup/fixtures/pe.conf"
    command = "ref_arch_setup install #{primary_master} #{pe_tarball} #{pe_conf}"

    puts command
    on controller, command
  end

  step "run puppet agent" do
    on target_master, "puppet agent -t"
  end

  teardown do
    # TODO: make this a task
    uninstall = "cd /opt/puppetlabs/bin/ && ./puppet-enterprise-uninstaller -d -p -y"
    remove_temp = "rm -rf /tmp/ref_arch_setup"

    puts "Uninstalling puppet on #{target_master}:"
    puts uninstall
    puts
    on target_master, uninstall

    puts "Removing temp work directory on #{target_master}:"
    puts remove_temp
    puts
    on target_master, remove_temp
  end
end
