{
  :ssh => {
    keys: [
      "id_rsa_acceptance", "#{ENV['HOME']}/.ssh/id_rsa-acceptance"
    ]
  },
  :preserve_hosts              => "always",
  :xml                         => true,
  :timesync                    => false,
  :repo_proxy                  => true,
  :add_el_extras               => false,
  :forge_host                  => "forge-aio01-petest.puppetlabs.com",
  :'master-start-curl-retries' => 30,
  :type                        => "pe",
  :pre_suite                   => [
    "acceptance/pre_suites/10_setup_ssh.rb",
    "acceptance/pre_suites/20_setup_ruby.rb",
    "acceptance/pre_suites/30_setup_ras.rb",
    "acceptance/pre_suites/40_download_pe_tarball.rb"
  ],
  :tests => [
    "acceptance/tests/10_install_test_remote_master_tarball_url.rb",
    "acceptance/tests/20_install_test_remote_master_tarball_path_controller.rb",
    "acceptance/tests/30_install_test_remote_master_tarball_path_master.rb" # ,
    # "acceptance/tests/40_install_test_local_master_tarball_url.rb",
    # "acceptance/tests/50_install_test_local_master_tarball_path.rb"
  ],
  "is_puppetserver"            => true,
  "use-service"                => true, # use service scripts to start/stop stuff
  "puppetservice"              => "pe-puppetserver",
  "puppetserver-confdir"       => "/etc/puppetlabs/puppetserver/conf.d",
  "puppetserver-config"        => "/etc/puppetlabs/puppetserver/conf.d/puppetserver.conf"
}
