test_name "perform install on local master with tarball path" do
  step "perform install" do
    filename = "puppet-enterprise-2019.0-rc1-7-gd82666f-el-7-x86_64.tar"
    primary_master = "--primary-master=localhost"
    pe_tarball = "--pe-tarball=#{BEAKER_RAS_PATH}/fixtures/#{filename}"
    pe_conf = "--pe-conf=#{BEAKER_RAS_PE_CONF}"
    command = "ref_arch_setup install #{primary_master} #{pe_tarball} #{pe_conf}"

    puts command
    on controller, command
  end

  step "run puppet agent" do
    fake_puppet_path = "/tmp/ref_arch_setup/puppet-enterprise-*"
    command = "#{fake_puppet_path}/puppet agent -t"

    on controller, command
  end

  teardown do
    ras_docker_teardown(controller)
  end
end
