test_name "install RAS on controller" do
  step "copy RAS to controller" do
    scp_to(controller, "#{__dir__}/../../../ref_arch_setup", "ref_arch_setup")
    on controller, "rm -f ref_arch_setup/Gemfile.lock"
  end

  step "install RAS on controller" do
    on controller, "cd ref_arch_setup && bundle install && rake gem:install"
  end
end
