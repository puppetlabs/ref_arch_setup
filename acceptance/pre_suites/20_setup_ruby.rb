test_name "install rvm and ruby on controller" do
  step "handle key" do
    key = "409B6B1796C275462A1703113804BB82D39DC0E3"
    command = "gpg --keyserver hkp://keys.gnupg.net --recv-keys #{key}"
    alt_command = "command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -"
    begin
      puts command
      puts

      on controller, command
    rescue
      puts "Failed to retrieve key; attempting alternative:"
      puts alt_command
      puts

      on controller, alt_command
    end
  end

  step "install rvm" do
    command = "curl -sSL https://get.rvm.io | bash -s stable"
    on controller, command
  end

  # bolt requires 2.3 or above
  step "install ruby" do
    on controller, "rvm install 2.4.2"
  end
end
