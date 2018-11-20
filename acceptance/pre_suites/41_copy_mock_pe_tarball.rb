test_name "copy mock PE tarball" do
  step "copy mock PE tarball to master" do
    scp_to(target_master, "#{__dir__}/../../fixtures/tarball", "ref_arch_setup")
  end
end
