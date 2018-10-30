
test_name "install bolt pkg" do
  pkg_file = "puppet-bolt-1.1.0.14.g7e00b65-1.el7.x86_64.rpm"
  step "copy custom bolt package to controller" do
    scp_to(controller, "#{__dir__}/../../fixtures/#{pkg_file}", pkg_file.to_s)
  end
  install_bolt_pkg(controller)

  # when we get the package from an http, we need to do the below, but from a file we do not...
  # step "install bolt repo" do
  #   command = "yum install -y puppet-bolt-1.*"
  #   puts command
  #   on controller, command
  # end
end
