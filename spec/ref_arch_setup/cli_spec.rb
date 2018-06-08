require "spec_helper"

describe RefArchSetup::CLI do
  let(:no_options)          { {} }
  let(:good_options)        { {} }
  let(:missing_arg_options) { {} }
  let(:cli)                 { RefArchSetup::CLI.new(no_options) }
  let(:install_obj)         { Class.new }

  good_options = { "target_host" => "local://localhost", "pe_tarball_path" => "goo", \
                   "pe_conf_path" => "boo" }
  missing_arg_options = { "target_host" => "--pe_tarball_path", "pe_conf_path" => "boo" }

  describe "Initialize" do
    it "check cli object initialization" do
      expect(cli.instance_variable_get("@options")).to eq(no_options)
    end
  end

  describe "check_for_missing_value" do
    it "nothing missing" do
      cli.instance_variable_set(:@options, good_options)
      expect { cli.check_for_missing_value }.not_to raise_error
    end
    it "something missing" do
      cli.instance_variable_set(:@options, missing_arg_options)
      expect { cli.check_for_missing_value }.to \
        raise_error(OptionParser::MissingArgument, /target_host/)
    end
  end

  describe "check_option" do
    it "option was given" do
      cli.instance_variable_set(:@options, good_options)
      expect { cli.check_option("target_host", "install") }.not_to raise_error
    end
    it "option was not given" do
      cli.instance_variable_set(:@options, good_options)
      expect { cli.check_option("fake_fake", "install") }.to \
        raise_error(OptionParser::MissingOption, /--fake-fake.*install/)
    end
  end

  describe "install" do
    it "install worked" do
      cli.instance_variable_set(:@options, good_options)
      expect(cli).to receive(:check_for_missing_value).and_return(true)
      expect(cli).to receive(:check_option).and_return(true).at_least(:once)
      expect(RefArchSetup::Install).to receive(:new).and_return(install_obj)
      expect(install_obj).to receive(:bootstrap_mono).and_return(true)
      expect(cli.install).to eq(true)
    end
    it "install failed" do
      cli.instance_variable_set(:@options, good_options)
      expect(cli).to receive(:check_for_missing_value).and_return(true)
      expect(cli).to receive(:check_option).and_return(true).at_least(:once)
      expect(RefArchSetup::Install).to receive(:new).and_return(install_obj)
      expect(install_obj).to receive(:bootstrap_mono).and_return(false)
      expect(cli.install).to eq(false)
    end
  end
end
