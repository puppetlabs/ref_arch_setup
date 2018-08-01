test_name "install rvm, ruby, and bolt on controller" do
  step "install rvm" do
    hosts = [controller]
    key = "409B6B1796C275462A1703113804BB82D39DC0E3"
    gpg_command = "gpg --keyserver hkp://keys.gnupg.net --recv-keys #{key}"
    curl_command = "curl -sSL https://get.rvm.io | bash -s stable"
    on hosts, "#{gpg_command} && #{curl_command}"
  end

  step "install ruby" do
    hosts = [controller]
    on hosts, "rvm install ruby"
  end

  step "install bolt" do
    hosts = [controller]
    on hosts, "gem install bolt"
  end
end
