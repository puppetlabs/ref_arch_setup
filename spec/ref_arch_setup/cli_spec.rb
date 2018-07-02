require "spec_helper"

describe RefArchSetup::CLI do
  let(:no_options)          { {} }
  let(:good_options)        { {} }
  let(:missing_arg_options) { {} }
  let(:cli)                 { RefArchSetup::CLI.new(no_options) }
  let(:install_obj)         { Class.new }

  good_options = { "primary_master" => "local://localhost", "pe_tarball" => "goo", \
                   "pe_conf" => "boo" }
  missing_arg_options = { "primary_master" => "--pe_tarball", "pe_conf" => "boo" }

  describe "Initialize" do
    it "check cli object initialization" do
      expect(cli.instance_variable_get("@options")).to eq(no_options)
    end
  end

  describe "check_for_missing_value" do
    context "when no values are missing" do
      it "does not raise an error" do
        cli.instance_variable_set(:@options, good_options)
        expect { cli.check_for_missing_value }.not_to raise_error
      end
    end

    context "when values are missing" do
      it "raises an OptionParser::MissingArgument error" do
        cli.instance_variable_set(:@options, missing_arg_options)
        expect { cli.check_for_missing_value }.to \
          raise_error(OptionParser::MissingArgument, /primary_master/)
      end
    end
  end

  describe "check_option" do
    context "when no options are missing" do
      it "does not raise an error" do
        cli.instance_variable_set(:@options, good_options)
        expect { cli.check_option("primary_master", "install") }.not_to raise_error
      end
    end

    context "when options are missing" do
      it "raises an OptionParser::MissingOption error" do
        cli.instance_variable_set(:@options, good_options)
        expect { cli.check_option("fake_fake", "install") }.to \
          raise_error(OptionParser::MissingOption, /--fake-fake.*install/)
      end
    end
  end

  describe "run" do
    context "when given only a command to run" do
      context "when the command returns true" do
        it "runs the command and returns true" do
          expect(cli).to receive(:check_for_missing_value).and_return(true)
          expect(cli).to receive(:install).and_return(true)
          expect(cli.run("install")).to eq(true)
        end
      end
      context "when the command returns false" do
        it "runs the command and returns false" do
          expect(cli).to receive(:check_for_missing_value).and_return(true)
          expect(cli).to receive(:install).and_return(false)
          expect(cli.run("install")).to eq(false)
        end
      end
    end
    context "when given a command and subcommand to run" do
      it "runs the subcommand and returns true" do
        expect(cli).to receive(:check_for_missing_value).and_return(true)
        expect(cli).to receive(:install_bootstrap).and_return(true)
        expect(cli.run("install", "bootstrap")).to eq(true)
      end
    end
  end

  describe "install" do
    context "when no options are given" do
      context "when install_generate_pe_conf fails" do
        it "calls only subcommands up to install_generate_pe_conf and returns false" do
          expect(cli).to receive(:install_generate_pe_conf).and_return(false)
          expect(cli).not_to receive(:install_bootstrap)
          expect(cli).to receive(:puts).with("Running install command")
          expect(cli.install).to eq(false)
        end
      end
      context "when install_bootstrap fails" do
        it "calls only subcommands up to install_bootstrap and returns false" do
          expect(cli).to receive(:install_generate_pe_conf).and_return(true)
          expect(cli).to receive(:install_bootstrap).and_return(false)
          expect(cli).not_to receive(:install_infra_agent_install)
          expect(cli).to receive(:puts).with("Running install command")
          expect(cli.install).to eq(false)
        end
      end
      context "when install_pe_infra_agent_install fails" do
        it "calls only subcommands up to install_pe_infra_agent_install and returns false" do
          expect(cli).to receive(:install_generate_pe_conf).and_return(true)
          expect(cli).to receive(:install_bootstrap).and_return(true)
          expect(cli).to receive(:install_pe_infra_agent_install).and_return(false)
          expect(cli).not_to receive(:install_configure)
          expect(cli).to receive(:puts).with("Running install command")
          expect(cli.install).to eq(false)
        end
      end
      context "when install_configure fails" do
        it "calls only subcommands up to install_configure and returns false" do
          expect(cli).to receive(:install_generate_pe_conf).and_return(true)
          expect(cli).to receive(:install_bootstrap).and_return(true)
          expect(cli).to receive(:install_pe_infra_agent_install).and_return(true)
          expect(cli).to receive(:install_configure).and_return(false)
          expect(cli).to receive(:puts).with("Running install command")
          expect(cli.install).to eq(false)
        end
      end
      context "when all subcommand pass" do
        it "calls all subcommands and returns true" do
          expect(cli).to receive(:install_generate_pe_conf).and_return(true)
          expect(cli).to receive(:install_bootstrap).and_return(true)
          expect(cli).to receive(:install_pe_infra_agent_install).and_return(true)
          expect(cli).to receive(:install_configure).and_return(true)
          expect(cli).to receive(:puts).with("Running install command")
          expect(cli.install).to eq(true)
        end
      end
    end
    context "when pe_conf_path option is given" do
      it "does not call install_generate_pe_conf but calls the rest of the subcommands" do
        cli.instance_variable_set(:@options, good_options)
        expect(cli).not_to receive(:install_generate_pe_conf)
        expect(cli).to receive(:install_bootstrap).and_return(true)
        expect(cli).to receive(:install_pe_infra_agent_install).and_return(true)
        expect(cli).to receive(:install_configure).and_return(true)
        expect(cli).to receive(:puts).with("Running install command")
        expect(cli.install).to eq(true)
      end
    end
  end

  describe "install_generate_pe_conf" do
    context "placeholder" do
      it "returns true" do
        cli.instance_variable_set(:@options, good_options)
        expect(cli).to receive(:puts).with("Running generate-pe-conf subcommand of install command")
        expect(cli.install_generate_pe_conf).to eq(true)
      end
    end
  end

  describe "install_bootstrap" do
    context "when the install works and returns true" do
      it "returns true" do
        cli.instance_variable_set(:@options, good_options)
        expect(cli).to receive(:check_option).and_return(true).at_least(:once)
        expect(RefArchSetup::Install).to receive(:new).and_return(install_obj)
        expect(install_obj).to receive(:bootstrap).and_return(true)
        expect(cli).to receive(:puts).with("Running bootstrap subcommand of install command")
        expect(cli.install_bootstrap).to eq(true)
      end
    end
    context "when the install fails and returns false" do
      it "returns false" do
        cli.instance_variable_set(:@options, good_options)
        expect(cli).to receive(:check_option).and_return(true).at_least(:once)
        expect(RefArchSetup::Install).to receive(:new).and_return(install_obj)
        expect(install_obj).to receive(:bootstrap).and_return(false)
        expect(cli).to receive(:puts).with("Running bootstrap subcommand of install command")
        expect(cli.install_bootstrap).to eq(false)
      end
    end
  end

  describe "install_pe_infra_agent_install" do
    context "placeholder" do
      it "returns true" do
        cli.instance_variable_set(:@options, good_options)
        expect(cli).to receive(:puts)\
          .with("Running pe-infra-agent-install subcommand of install command")
        expect(cli.install_pe_infra_agent_install).to eq(true)
      end
    end
  end

  describe "install_configure" do
    context "placeholder" do
      it "returns true" do
        cli.instance_variable_set(:@options, good_options)
        expect(cli).to receive(:puts).with("Running configure subcommand of install command")
        expect(cli.install_configure).to eq(true)
      end
    end
  end
end
