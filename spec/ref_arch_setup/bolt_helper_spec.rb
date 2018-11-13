require "spec_helper"

describe RefArchSetup::BoltHelper do
  let(:nodes)               { "local://localhost" }
  let(:dir)                 { "/tmp/ref_arch_setup" }
  let(:cmd)                 { "echo foo" }
  let(:task)                { "ref_arch_setup::foo" }
  let(:plan)                { "ref_arch_setup::foo_plan" }
  let(:params)              { { "VAR1" => "1", "VAR2" => "2" } }
  let(:params_str)          { "VAR1=1 VAR2=2" }
  let(:bolt_default_opts)   { { "run-as" => "root" } }
  let(:bolt_default_string) { "--run-as root --no-host-key-check" }
  let(:bolt_user_opts)      { { "user" => "my_user", "password" => "my_password" } }
  let(:bolt_user_string)    { "--user my_user --password my_password" }
  let(:bolt_pkey_opts)      { { "private-key" => "private_key_path" } }
  let(:bolt_pkey_string)    { "--private-key private_key_path" }
  let(:source)              { "/tmp/foo" }
  let(:destination)         { "/tmp/bar" }

  after do
    RefArchSetup::BoltHelper.init
  end

  describe "init" do
    it "sets the bolt options to the default" do
      RefArchSetup::BoltHelper.bolt_options = bolt_user_opts
      RefArchSetup::BoltHelper.init
      expect(expect(RefArchSetup::BoltHelper.bolt_options_string)
       .to(eq(" #{bolt_default_string}")))
    end
  end

  describe "bolt_options" do
    context "when the overwrite option is specified as true" do
      it "uses the user-specified options" do
        RefArchSetup::BoltHelper.bolt_options(bolt_user_opts, true)
        expect(expect(RefArchSetup::BoltHelper.bolt_options_string)
          .to(eq(" #{bolt_user_string}")))
      end
    end

    context "when the overwrite option is specified as false" do
      it "merges the user-specified options with the default options" do
        RefArchSetup::BoltHelper.bolt_options(bolt_user_opts, false)

        expect(expect(RefArchSetup::BoltHelper.bolt_options_string)
          .to(eq(" #{bolt_default_string} #{bolt_user_string}")))
      end
    end

    context "when the overwrite option is not specified" do
      it "merges the user-specified options with the default options" do
        RefArchSetup::BoltHelper.bolt_options(bolt_user_opts)

        expect(expect(RefArchSetup::BoltHelper.bolt_options_string)
          .to(eq(" #{bolt_default_string} #{bolt_user_string}")))
      end
    end
  end

  describe "make_dir" do
    before do
      @expected_command = "mkdir -p #{dir}"
      @expected_error = "ERROR: Failed to make dir #{dir} on all nodes"
    end

    context "when run_cmd_with_bolt returns output" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)
          .with(@expected_command, nodes, @expected_error).and_return(true)
        expect(RefArchSetup::BoltHelper.make_dir(dir, nodes)).to eq(true)
      end
    end

    context "when run_cmd_with_bolt raises an error" do
      it "does not trap the error" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)
          .with(@expected_command, nodes, @expected_error).and_raise(RuntimeError, @expected_error)
        expect { RefArchSetup::BoltHelper.make_dir(dir, nodes) }
          .to raise_error(RuntimeError, @expected_error)
      end
    end
  end

  describe "run_command" do
    before do
      @expected_command = "bolt command run '#{cmd}' --nodes #{nodes} #{bolt_default_string}"
    end

    context "when the command returns true" do
      it "outputs informative messages" do
        expected_output = "All Good"
        expected_status = 0

        expect(RefArchSetup::BoltHelper).to receive(:`)
          .with(@expected_command).and_return(expected_output)

        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(true) # rubocop:disable Style/SpecialGlobalVars

        expect(RefArchSetup::BoltHelper).to receive(:puts).with(no_args)
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts)
          .with("Exit status was: #{expected_status}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")

        RefArchSetup::BoltHelper.run_command(@expected_command)
      end

      it "returns the output" do
        expected_output = "All Good"
        expected_status = 0
        expect(RefArchSetup::BoltHelper).to receive(:`)
          .with(@expected_command).and_return(expected_output)

        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(true) # rubocop:disable Style/SpecialGlobalVars

        allow(RefArchSetup::BoltHelper).to receive(:puts)

        expect(RefArchSetup::BoltHelper.run_command(@expected_command)).to eq(expected_output)
      end
    end

    context "when the command returns false" do
      it "outputs informative messages (and raises an error)" do
        expected_output = "No Good"
        expected_status = 1

        expect(RefArchSetup::BoltHelper).to receive(:`)
          .with(@expected_command).and_return(expected_output)

        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(false) # rubocop:disable Style/SpecialGlobalVars

        expect(RefArchSetup::BoltHelper).to receive(:puts).with(no_args)
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts)
          .with("Exit status was: #{expected_status}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")

        expect { RefArchSetup::BoltHelper.run_command(@expected_command) }
          .to raise_error(RefArchSetup::BoltHelper::BoltCommandError)
      end

      context "when the error is specified" do
        it "raises the specified error" do
          error = "ERROR: bolt command failed!"
          expected_output = "No Good"
          expected_status = 1

          expect(RefArchSetup::BoltHelper).to receive(:`)
            .with(@expected_command).and_return(expected_output)

          `(exit #{expected_status})`
          # rubocop:disable Style/SpecialGlobalVars
          expect($?).to receive(:success?).and_return(false)
          # rubocop:enable Style/SpecialGlobalVars

          allow(RefArchSetup::BoltHelper).to receive(:puts)

          expect { RefArchSetup::BoltHelper.run_command(@expected_command, error) }
            .to raise_error(RefArchSetup::BoltHelper::BoltCommandError, error)
        end
      end

      context "when the error is not specified" do
        it "raises the default error" do
          error = "ERROR: command failed!"
          expected_output = "No Good"
          expected_status = 1

          expect(RefArchSetup::BoltHelper).to receive(:`)
            .with(@expected_command).and_return(expected_output)

          `(exit #{expected_status})`
          # rubocop:disable Style/SpecialGlobalVars
          expect($?).to receive(:success?).and_return(false)
          # rubocop:enable Style/SpecialGlobalVars

          allow(RefArchSetup::BoltHelper).to receive(:puts)

          expect { RefArchSetup::BoltHelper.run_command(@expected_command) }
            .to raise_error(RefArchSetup::BoltHelper::BoltCommandError, error)
        end
      end
    end
  end

  describe "run_cmd_with_bolt" do
    before do
      @expected_command = "bolt command run '#{cmd}' --nodes #{nodes} #{bolt_default_string}"
      @default_error_message = "ERROR: bolt command failed!"
      @spec_error_message = "ERROR: calling method provided this message!"
    end

    context "when bolt succeeds and returns output" do
      it "returns the expected output" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @default_error_message).and_return(expected_output)

        expect(RefArchSetup::BoltHelper.run_cmd_with_bolt(cmd, nodes)).to eq(expected_output)
      end
    end

    context "when bolt fails" do
      context "when an error message is specified" do
        it "raises the specified error" do
          expect(RefArchSetup::BoltHelper).to receive(:run_command)
            .with(@expected_command, @spec_error_message)
            .and_raise(RuntimeError, @spec_error_message)

          expect { RefArchSetup::BoltHelper.run_cmd_with_bolt(cmd, nodes, @spec_error_message) }
            .to raise_error(RuntimeError, @spec_error_message)
        end
      end

      context "when an error message is not specified" do
        it "raises the default error" do
          expect(RefArchSetup::BoltHelper).to receive(:run_command)
            .with(@expected_command, @default_error_message)
            .and_raise(RuntimeError, @default_error_message)

          expect { RefArchSetup::BoltHelper.run_cmd_with_bolt(cmd, nodes) }
            .to raise_error(RuntimeError, @error_message)
        end
      end
    end

    context "when ssh user and password options are sent" do
      before do
        RefArchSetup::BoltHelper.bolt_options = bolt_user_opts
        @expected_command_with_ssh = "#{@expected_command} #{bolt_user_string}"
      end

      it "executes bolt command with the arguments" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command_with_ssh, @default_error_message).and_return(expected_output)

        RefArchSetup::BoltHelper.run_cmd_with_bolt(cmd, nodes)
      end
    end
    context "when ssh private key is sent" do
      before do
        RefArchSetup::BoltHelper.bolt_options = bolt_pkey_opts
        @expected_command_with_ssh = "#{@expected_command} #{bolt_pkey_string}"
      end

      it "executes bolt command with the arguments" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command_with_ssh, @default_error_message).and_return(expected_output)

        RefArchSetup::BoltHelper.run_cmd_with_bolt(cmd, nodes)
      end
    end
  end

  describe "run_task_with_bolt" do
    before do
      @expected_command = "bolt task run #{task} VAR1=1 VAR2=2 --modulepath "\
      "#{RefArchSetup::RAS_MODULE_PATH} --nodes #{nodes} #{bolt_default_string}"
      @error_message = "ERROR: bolt task failed!"
    end

    context "when a modulepath is specified" do
      expected_output = "All Good"
      modulepath = "./my_modules"

      it "uses the specified value" do
        # this updates @expected_command to specify the modulepath for this test only
        @expected_command = "bolt task run #{task} VAR1=1 VAR2=2 --modulepath "\
          "#{modulepath} --nodes #{nodes} #{bolt_default_string}"

        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_return(expected_output)

        RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes, modulepath)
      end
    end

    context "when bolt works and returns the output" do
      expected_output = "All Good"

      it "uses the default modulepath" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message)

        RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes)
      end

      it "returns the expected output" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_return(expected_output)

        expect(RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes))
          .to eq(expected_output)
      end
    end

    context "when bolt fails" do
      it "raises the specified error" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_raise(RuntimeError, @error_message)

        expect { RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes) }
          .to raise_error(RuntimeError, @error_message)
      end
    end

    context "when ssh private key is sent" do
      before do
        RefArchSetup::BoltHelper.bolt_options = bolt_pkey_opts
        @expected_command_with_ssh = "#{@expected_command} #{bolt_pkey_string}"
      end

      it "passes the argument to bolt" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command_with_ssh, @error_message).and_return(expected_output)

        RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes)
      end
    end
  end

  describe "run_plan_with_bolt" do
    before do
      @expected_command = "bolt plan run #{plan} VAR1=1 VAR2=2 --modulepath "\
      "#{RefArchSetup::RAS_MODULE_PATH} --nodes #{nodes} #{bolt_default_string}"
      @error_message = "ERROR: bolt plan failed!"
    end

    context "when a modulepath is specified" do
      expected_output = "All Good"
      modulepath = "./my_modules"

      it "uses the specified value" do
        # this updates @expected_command to specify the modulepath for this test only
        @expected_command = "bolt plan run #{plan} VAR1=1 VAR2=2 --modulepath "\
        "#{modulepath} --nodes #{nodes} #{bolt_default_string}"

        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_return(expected_output)

        expect(RefArchSetup::BoltHelper.run_plan_with_bolt(plan, params, nodes, modulepath))
          .to eq(expected_output)
      end
    end

    context "when bolt works and returns output" do
      expected_output = "All Good"

      it "uses the default modulepath" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_return(expected_output)

        RefArchSetup::BoltHelper.run_plan_with_bolt(plan, params, nodes)
      end

      it "returns the output" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_return(expected_output)

        expect(RefArchSetup::BoltHelper.run_plan_with_bolt(plan, params, nodes))
          .to eq(expected_output)
      end
    end

    context "when bolt fails" do
      it "raises the specified error" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_raise(RuntimeError, @error_message)

        expect { RefArchSetup::BoltHelper.run_plan_with_bolt(plan, params, nodes) }
          .to raise_error(RuntimeError, @error_message)
      end
    end

    context "when ssh private key is sent" do
      before do
        RefArchSetup::BoltHelper.bolt_options = bolt_pkey_opts
        @expected_command_with_ssh = "#{@expected_command} #{bolt_pkey_string}"
      end

      it "passes the argument to bolt" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:params_to_string)
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command_with_ssh, @error_message).and_return(expected_output)

        RefArchSetup::BoltHelper.run_plan_with_bolt(plan, params, nodes)
      end
    end
  end

  describe "run_forge_task_with_bolt" do
    context "when bolt works and returns output" do
      it "ensures the forge modules are installed" do
        expect(RefArchSetup::BoltHelper).to receive(:install_forge_modules)
        expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
        RefArchSetup::BoltHelper.run_forge_task_with_bolt(task, params, nodes)
      end

      it "returns the output" do
        modulepath = RefArchSetup::FORGE_MODULE_PATH
        expect(RefArchSetup::BoltHelper).to receive(:install_forge_modules)
        expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
          .with(task, params, nodes, modulepath).and_return(true)
        expect(RefArchSetup::BoltHelper.run_forge_task_with_bolt(task, params, nodes)).to eq(true)
      end
    end
  end

  describe "run_forge_plan_with_bolt" do
    context "when bolt works and returns output" do
      it "ensures the forge modules are installed" do
        expect(RefArchSetup::BoltHelper).to receive(:install_forge_modules)
        expect(RefArchSetup::BoltHelper).to receive(:run_plan_with_bolt)
        RefArchSetup::BoltHelper.run_forge_plan_with_bolt(plan, params, nodes)
      end

      it "returns the output" do
        expected_output = "All Good"
        modulepath = RefArchSetup::FORGE_MODULE_PATH
        expect(RefArchSetup::BoltHelper).to receive(:install_forge_modules)
        expect(RefArchSetup::BoltHelper).to receive(:run_plan_with_bolt)
          .with(plan, params, nodes, modulepath).and_return(expected_output)
        expect(RefArchSetup::BoltHelper.run_forge_plan_with_bolt(plan, params, nodes))
          .to eq(expected_output)
      end
    end
  end

  describe "params_to_string" do
    context "params has 2 values" do
      it "stringifies them correctly" do
        params = { "one" => "1", "two" => "2" }
        expected_str = "one=1 two=2"
        expect(RefArchSetup::BoltHelper.params_to_string(params)).to eq(expected_str)
      end
    end
    context "params has 1 values" do
      it "stringifies them correctly" do
        params = { "one" => "1" }
        expected_str = "one=1"
        expect(RefArchSetup::BoltHelper.params_to_string(params)).to eq(expected_str)
      end
    end
  end

  describe "upload_file" do
    before do
      @expected_command = "bolt file upload #{source} #{destination}" \
        " --nodes #{nodes} #{bolt_default_string}"
      @error_message = "ERROR: failed to upload file #{source} to #{destination} on #{nodes}"
    end

    context "when bolt works and returns true" do
      it "returns the expected output" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_return(expected_output)

        expect(RefArchSetup::BoltHelper.upload_file(source, destination, nodes))
          .to eq(expected_output)
      end
    end

    context "when bolt fails" do
      it "raises the specified error" do
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_raise(RuntimeError, @error_message)

        expect { RefArchSetup::BoltHelper.upload_file(source, destination, nodes) }
          .to raise_error(RuntimeError, @error_message)
      end
    end

    context "when ssh private key is sent" do
      before do
        RefArchSetup::BoltHelper.bolt_options = bolt_pkey_opts
        @expected_command_with_ssh = "#{@expected_command} #{bolt_pkey_string}"
      end

      it "passes the argument to bolt" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command_with_ssh, @error_message).and_return(expected_output)

        RefArchSetup::BoltHelper.upload_file(source, destination, nodes)
      end
    end
  end

  describe "install_forge_modules" do
    before do
      @expected_command = "cd #{RefArchSetup::RAS_PATH} && bolt puppetfile install --modulepath "\
      "#{RefArchSetup::FORGE_MODULE_PATH}"
      @error_message = "ERROR: bolt puppetfile install failed!"
    end

    context "when bolt works and returns output" do
      it "returns the expected output" do
        expected_output = "All Good"

        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_return(expected_output)

        expect(RefArchSetup::BoltHelper.install_forge_modules).to eq(expected_output)
      end
    end

    context "when bolt fails" do
      it "does not trap the error" do
        expect(RefArchSetup::BoltHelper).to receive(:run_command)
          .with(@expected_command, @error_message).and_raise(RuntimeError, @error_message)

        expect { RefArchSetup::BoltHelper.install_forge_modules }
          .to raise_error(RuntimeError, @error_message)
      end
    end
  end
end
