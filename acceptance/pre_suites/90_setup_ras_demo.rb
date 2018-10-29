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

test_name "output host info" do
  step "output the host info" do
    puts
    puts "controller(s): #{controller}"
    puts "master(s): #{target_master}"
    puts
  end
end
