test_name "perform install on remote master with tarball path on controller" do
  step "perform install" do
    # TODO: use pe_version from BoltHelper
    pe_version = "puppet-enterprise-2018.1.0-rc14-el-7-x86_64"
    primary_master = "--primary-master=#{target_master}"
    pe_tarball = "--pe-tarball=/tmp/ras/#{pe_version}.tar.gz"
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
