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
end

test_name "install docker-compose on the controller" do
  step "install docker-compose" do
    docker_compose = "docker-compose-$(uname -s)-$(uname -m)"
    url = "https://github.com/docker/compose/releases/download/1.23.1/#{docker_compose}"
    command = "curl -L #{url}  -o /usr/local/bin/docker-compose"
    puts command
    on controller, command
  end

  step "update docker-compose permissions" do
    command = "chmod +x /usr/local/bin/docker-compose"
    puts command
    on controller, command
  end
end
