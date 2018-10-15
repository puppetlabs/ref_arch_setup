test_name "download PE tarball" do
  step "download tarball using download_pe_tarball task" do
    pe_url = get_pe_tarball_url(target_master)
    bolt = "bolt task run"
    task = "ref_arch_setup::download_pe_tarball"
    url = "url=#{pe_url}"
    destination = "destination=#{BEAKER_RAS_PATH}"
    modulepath = "--modulepath #{BEAKER_RAS_MODULES_PATH}"
    nodes = "--nodes localhost,#{target_master}"
    user = "--user root"

    command = "#{bolt} #{task} #{url} #{destination} #{modulepath} #{nodes} #{user}"
    puts command

    on controller, command
  end
end
