test_name "install docker on the controller" do
  step "install dependencies" do
    command = "yum install -y yum-utils device-mapper-persistent-data lvm2 git"
    puts command
    on controller, command
  end

  step "add docker repo" do
    url = "https://download.docker.com/linux/centos/docker-ce.repo"
    command = "yum-config-manager --add-repo #{url}"
    puts command
    on controller, command
  end

  step "install docker" do
    command = "yum install -y docker-ce"
    puts command
    on controller, command
  end

  step "start docker" do
    command = "systemctl start docker"
    puts command
    on controller, command
  end

  step "install docker-compose" do
    url = "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)"
    command = "curl -L #{url}  -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose"
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
