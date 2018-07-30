test_name "perform install on remote master with tarball url" do
  step "perform install" do
    primary_master = "--primary-master=#{target_master}"
    pe_tarball = "--pe-tarball=http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1/puppet-enterprise-2018.1.0-rc14-el-7-x86_64.tar.gz"
    pe_conf = "--pe-conf=/root/ref_arch_setup/fixtures/pe.conf"
    command = "ref_arch_setup install #{primary_master} #{pe_tarball} #{pe_conf}"

    puts command

    on controller, command

  end

  step "run puppet agent" do
    on target_master, "puppet agent -t"
  end
end
