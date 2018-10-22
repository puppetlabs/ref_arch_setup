test_name "perform install on remote master with tarball url" do
  step "perform install" do
    pe_url = get_pe_tarball_url(target_master)
    primary_master = "--primary-master=#{target_master}"
    pe_tarball = "--pe-tarball=#{pe_url}"
    pe_conf = "--pe-conf=#{BEAKER_RAS_PE_CONF}"
    command = "ref_arch_setup install #{primary_master} #{pe_tarball} #{pe_conf}"

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
