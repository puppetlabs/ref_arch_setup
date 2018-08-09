test_name "perform install on local master with tarball path" do
  step "perform install" do
    filename = get_pe_tarball_filename(controller)
    primary_master = "--primary-master=localhost"
    pe_tarball = "--pe-tarball=#{RAS_PATH}/#{filename}"
    pe_conf = "--pe-conf=#{RAS_PE_CONF}"
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
