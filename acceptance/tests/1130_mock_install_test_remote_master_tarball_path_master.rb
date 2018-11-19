test_name "perform install on remote master with tarball path on master" do
  step "perform install" do
    # file is copied to the target master in pre_suites/41_copy_mock_pe_tarball.rb
    filename = "puppet-enterprise-2019.0-rc1-7-gd82666f-el-7-x86_64.tar"
    primary_master = "--primary-master=#{target_master}"
    pe_tarball = "--pe-tarball=#{target_master}:/root/ref_arch_setup/#{filename}"
    pe_conf = "--pe-conf=#{BEAKER_RAS_PE_CONF}"
    command = "ref_arch_setup install #{primary_master} #{pe_tarball} #{pe_conf}"

    puts command
    on controller, command
  end

  step "run puppet agent" do
    run_mock_puppet_agent(target_master)
  end

  teardown do
    ras_docker_teardown(target_master)
  end
end
