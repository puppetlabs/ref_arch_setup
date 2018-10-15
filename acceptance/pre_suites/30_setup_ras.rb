test_name "install RAS on controller" do
  step "copy RAS gem to controller" do
    scp_to(controller, "#{__dir__}/../../pkg", "ref_arch_setup")
  end

  step "install RAS on controller" do
    version = RefArchSetup::Version::STRING
    gem = "ref_arch_setup-#{version}.gem"
    command = "gem install #{BEAKER_RAS_PATH}/#{gem}"

    on controller, command
  end

  step "copy fixtures and modules" do
    ras_gem_path = get_ras_gem_path(controller)
    on controller, "cp -r #{ras_gem_path}/fixtures #{BEAKER_RAS_PATH}"
    on controller, "cp -r #{ras_gem_path}/modules #{BEAKER_RAS_PATH}"
  end
end
