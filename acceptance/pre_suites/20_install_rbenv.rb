# rubocop:disable Metrics/BlockLength
test_name "install rbenv" do
  step "install dependencies" do
    command = "yum install -y git-core zlib zlib-devel gcc-c++ patch" \
              " readline readline-devel libyaml-devel libffi-devel openssl-devel" \
              " make bzip2 autoconf automake libtool bison curl sqlite-devel"

    puts command
    on controller, command
  end

  step "install rbenv" do
    url = "https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer"
    command = "curl -fsSL #{url} | bash"

    puts command

    begin
      on controller, command
    rescue
      puts "Error encountered... this is expected from rbenv-doctor"
    end
  end

  step "export path" do
    line = "export PATH=$PATH:$HOME/.rbenv/bin"
    command = "echo #{line} >> ~/.bashrc"

    puts command
    on controller, command
  end

  step "rbenv init" do
    line = 'eval "$(rbenv init -)"'
    command = "echo #{line} >> ~/.bashrc"

    puts command
    on controller, command
  end

  step "install ruby" do
    command = "rbenv install -v 2.4.2"

    puts command
    on controller, command
  end

  step "set global" do
    command = "rbenv global 2.4.2"

    puts command
    on controller, command
  end
end
