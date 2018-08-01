test_name "download PE tarball" do
  step "download tarball using download_pe_tarball task" do
    # TODO: use value from BoltHelper
    pe_version = "puppet-enterprise-2018.1.0-rc14-el-7-x86_64"
    pe_dir = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1"
    pe_url = "#{pe_dir}/#{pe_version}.tar.gz"

    bolt = "bolt task run"
    task = "ref_arch_setup::download_pe_tarball"

    # url = "url=#{@pe_url}"
    url = "url=#{pe_url}"

    destination = "destination=/tmp/ras"
    modulepath = "--modulepath /root/ref_arch_setup/modules"
    nodes = "--nodes localhost,#{target_master_c}"
    user = "--user root"

    command = "#{bolt} #{task} #{url} #{destination} #{modulepath} #{nodes} #{user}"
    puts command

    on controller, command
  end
end
