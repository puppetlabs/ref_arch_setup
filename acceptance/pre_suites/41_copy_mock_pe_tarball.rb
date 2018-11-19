test_name "copy mock tarball PE tarball" do
  step "copy mock tarball to master" do
    scp_to(target_master, "#{__dir__}/../../fixtures", "ref_arch_setup")
  end
end
