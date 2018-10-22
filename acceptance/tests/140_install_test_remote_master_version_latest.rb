test_name "perform install on remote master with latest version" do
  step "perform install" do
    pe_version = "--pe_version=latest"
    primary_master = "--primary-master=#{target_master}"
    pe_conf = "--pe-conf=#{BEAKER_RAS_PE_CONF}"
    command = "ref_arch_setup install #{primary_master} #{pe_conf} #{pe_version}"

    puts command
    on controller, command
  end

  step "run puppet agent" do
    on target_master, "puppet agent -t"
  end

  teardown do
    ras_teardown(target_master)
  end
end
