test_name "install required gems on controller" do
  step "install rake" do
    on controller, "gem install rake"
  end

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

test_name "host info" do
  step "output host info" do
    puts
    puts "controller(s): #{controller}"
    puts "master(s): #{target_master}"
    puts
  end
end
