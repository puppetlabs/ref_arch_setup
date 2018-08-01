require "./acceptance/helpers/beaker_helper"
test_name "perform install on remote master with tarball url" do
  step "perform install" do
    pe_url = BeakerHelper.get_pe_tarball_url(target_master)
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
