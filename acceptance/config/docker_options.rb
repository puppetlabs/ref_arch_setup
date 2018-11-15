{
  :ssh => {
    keys: [
      "id_rsa_acceptance", "#{ENV['HOME']}/.ssh/id_rsa-acceptance"
    ]
  },
  :helper => [
    "acceptance/helpers/beaker_helper.rb"
  ],
  :xml                         => true,
  :timesync                    => false,
  :repo_proxy                  => true,
  :add_el_extras               => false,
  :forge_host                  => "forge-aio01-petest.puppetlabs.com",
  :'master-start-curl-retries' => 30,
  :type                        => "pe",
  :pre_suite                   => [
    "acceptance/pre_suites/30_setup_ras.rb",
    "acceptance/pre_suites/99_output_host_info.rb"
  ],
  :tests => [
    # "acceptance/tests/docker/00_docker_test.rb",
    "acceptance/tests/1220_mock_install_test_local_master_tarball_path.rb"
  ],
  "is_puppetserver"            => true,
  "use-service"                => true, # use service scripts to start/stop stuff
  "puppetservice"              => "pe-puppetserver",
  "puppetserver-confdir"       => "/etc/puppetlabs/puppetserver/conf.d",
  "puppetserver-config"        => "/etc/puppetlabs/puppetserver/conf.d/puppetserver.conf"
}
