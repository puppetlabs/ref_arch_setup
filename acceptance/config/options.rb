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
    "acceptance/pre_suites/setup_ssh.rb",
    "acceptance/pre_suites/setup_ruby.rb",
    "acceptance/pre_suites/setup_ras.rb"
  ],
  :tests => [
    "acceptance/tests/install_test.rb"
  ],
  "is_puppetserver"            => true,
  "use-service"                => true, # use service scripts to start/stop stuff
  "puppetservice"              => "pe-puppetserver",
  "puppetserver-confdir"       => "/etc/puppetlabs/puppetserver/conf.d",
  "puppetserver-config"        => "/etc/puppetlabs/puppetserver/conf.d/puppetserver.conf"
}
