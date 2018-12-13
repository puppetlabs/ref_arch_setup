test_name "install bolt pkg" do
  step "install bolt repo" do
    install_bolt_repo(controller)
  end

  step "install bolt package" do
    install_bolt_pkg(controller)
  end
end
