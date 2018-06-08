require "spec_helper"

describe RefArchSetup::Install do
  let(:target_master)   { "local://localhost" }
  let(:pe_conf_path)    { "/tmp/pe.conf" }
  let(:pe_tarball_path) { "/tmp/pe.tarball" }
  let(:install)         { RefArchSetup::Install.new(target_master) }

  describe "initialize" do
    it "checks that the passed in parameters get used" do
      temp_install = RefArchSetup::Install.new(target_master)
      expect(temp_install.instance_variable_get("@target_master")).to eq(target_master)
    end
  end

  describe "bootstrap_mono" do
    before do
      @expected_command = "PE_CONF_PATH=#{pe_conf_path};"
      @expected_command << "PE_TARBALL_PATH=#{pe_tarball_path};"
      @expected_command << "PE_TARGET_MASTER=#{target_master};"
      @expected_command << "bolt task run bogus::foo --modulepath #{RefArchSetup::RAS_MODULE_PATH}"
      @expected_command << " --nodes #{target_master}"
    end

    it "got a pass from bolt" do
      expected_output = "All Good"
      expected_status = 0
      expect(install).to receive(:`).with(@expected_command).and_return(expected_output)
      `(exit #{expected_status})`
      expect($?).to receive(:success?).and_return(true) # rubocop:disable Style/SpecialGlobalVars
      expect(install).to receive(:puts).with("Running: #{@expected_command}")
      expect(install).to receive(:puts).with("Exit status was: #{expected_status}")
      expect(install).to receive(:puts).with("Output was: #{expected_output}")
      expect(install.bootstrap_mono(pe_conf_path, pe_tarball_path, target_master)).to eq(true)
    end

    it "got a fail from bolt" do
      expected_output = "No Good"
      expected_status = 1
      expect(install).to receive(:`).with(@expected_command).and_return(expected_output)
      `(exit #{expected_status})`
      expect($?).to receive(:success?).and_return(false) # rubocop:disable Style/SpecialGlobalVars
      expect(install).to receive(:puts).with("Running: #{@expected_command}")
      expect(install).to receive(:puts).with("ERROR: bolt command failed!")
      expect(install).to receive(:puts).with("Exit status was: #{expected_status}")
      expect(install).to receive(:puts).with("Output was: #{expected_output}")
      expect(install.bootstrap_mono(pe_conf_path, pe_tarball_path, target_master)).to eq(false)
    end
  end
end
