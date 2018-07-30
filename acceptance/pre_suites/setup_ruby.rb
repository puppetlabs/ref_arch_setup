test_name "install RAS on controller" do

  step "install rvm, bundler, gem_of" do
    on controller, "gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
    on controller, "curl -sSL https://get.rvm.io | bash -s stable"
    on controller, "rvm install ruby"
    on controller, "gem install bundler"
    on controller, "gem install gem_of"
  end

end
