test_name "install RAS on controller" do
  step "copy RAS to controller" do
    hosts = [controller]
    scp_to(hosts, "#{__dir__}/../../pkg", "ref_arch_setup")
    scp_to(hosts, "#{__dir__}/../../fixtures", "ref_arch_setup")
    scp_to(hosts, "#{__dir__}/../../modules", "ref_arch_setup")
  end

  step "install RAS on controller and local masters" do
    hosts = [controller]
    version = RefArchSetup::Version::STRING
    gem = "ref_arch_setup-#{version}.gem"
    command = "cd ref_arch_setup && gem install --local #{gem}"
    on hosts, command
  end
end
