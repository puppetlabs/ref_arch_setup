test_name "output host info" do
  step "output the host info" do
    puts
    puts "controller(s): #{controller}"
    puts "master(s): #{target_master}"
    puts
  end
end
