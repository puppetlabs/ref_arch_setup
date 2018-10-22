test_name "perform install on remote master with tarball path on controller" do
  step "perform install" do
    filename = get_pe_tarball_filename(target_master)
    primary_master = "--primary-master=#{target_master}"
    pe_tarball = "--pe-tarball=#{BEAKER_RAS_PATH}/#{filename}"
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
