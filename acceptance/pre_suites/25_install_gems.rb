test_name "install bolt and gem-path on controller" do
  # ras requires bolt
  step "install bolt" do
    on controller, "gem install bolt"
  end

  # gem path is used to find ras
  step "install gem-path" do
    on controller, "gem install gem-path"
  end
end
