test_name "install RAS on controller" do
  step "copy RAS gem to controller" do
    scp_to(controller, "#{__dir__}/../../pkg", "ref_arch_setup")
  end

  install_ras_gem(controller)

  step "link RAS exe into path" do
    command = "ln -s /opt/puppetlabs/bolt/bin/ref_arch_setup /usr/local/bin/ref_arch_setup"

    on controller, command
  end

  step "copy fixtures and modules" do
    ras_gem_path = get_ras_gem_path(controller)
    on controller, "cp -r #{ras_gem_path}/fixtures #{BEAKER_RAS_PATH}"
    on controller, "cp -r #{ras_gem_path}/modules #{BEAKER_RAS_PATH}"
  end
end
