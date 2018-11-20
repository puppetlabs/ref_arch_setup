
test_name "install bolt pkg" do
  pkg_file = "puppet-bolt-1.1.0.14.g7e00b65-1.el7.x86_64.rpm"
  step "copy custom bolt package to controller" do
    scp_to(controller, "#{__dir__}/../../fixtures/#{pkg_file}", pkg_file.to_s)
  end
  install_bolt_pkg(controller)

  # This is temporarily commented out.  When installing from a URL this needs to be run
  # But when installing from a local file it doesn't
  # Installing from the local specialized copy of bolt is just temporary until we decide how to
  # release ras now that we can't use bolt as a gem
  # step "install bolt repo" do
  #   command = "yum install -y puppet-bolt-1.*"
  #   puts command
  #   on controller, command
  # end
end
