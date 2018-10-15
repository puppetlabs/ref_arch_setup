test_name "perform install on local master with tarball url" do
  step "perform install" do
    pe_url = get_pe_tarball_url(controller)
    primary_master = "--primary-master=localhost"
    pe_tarball = "--pe-tarball=#{pe_url}"
    pe_conf = "--pe-conf=#{BEAKER_RAS_PE_CONF}"
    command = "ref_arch_setup install #{primary_master} #{pe_tarball} #{pe_conf}"

    puts command
    on controller, command
  end

  step "run puppet agent" do
    on controller, "puppet agent -t"
  end

  teardown do
    ras_teardown(controller)
  end
end
