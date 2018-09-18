test_name "install bolt and gem-path on controller" do
  # gem path is used to find ras
  step "install gem-path" do
    on controller, "gem install gem-path"
  end
end
