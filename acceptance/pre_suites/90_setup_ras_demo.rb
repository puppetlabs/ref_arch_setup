test_name "install bundler to build the RAS gem on the controller" do
  step "install bundler" do
    on controller, "gem install bundler"
  end

  step "add be alias for bundle exec" do
    line = "alias be='bundle exec'"
    command = "echo \"#{line}\" >> ~/.bashrc"

    puts command
    on controller, command
  end
end
