require "spec_helper"

describe RefArchSetup::BoltHelper do
  let(:nodes)        { "local://localhost" }
  let(:dir)          { "/tmp/ref_arch_setup" }
  let(:cmd)          { "echo foo" }
  let(:task)         { "ref_arch_setup::foo" }
  let(:params)       { { "VAR1" => "1", "VAR2" => "2" } }
  let(:params_str)   { "VAR1=1 VAR2=2" }
  let(:source)       { "/tmp/foo" }
  let(:destination)  { "/tmp/bar" }

  describe "make_dir" do
    before do
      @expected_command = "[ -d #{dir} ] ||"
      @expected_command << " mkdir -p #{dir}"
    end

    context "when run_cmd_with_bolt returns true" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)\
          .with(@expected_command, nodes).and_return(true)
        expect(RefArchSetup::BoltHelper.make_dir(dir, nodes)).to eq(true)
      end
    end

    context "when run_cmd_with_bolt returns false" do
      it "returns false and output an error" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)\
          .with(@expected_command, nodes).and_return(false)
        expect(RefArchSetup::BoltHelper).to receive(:puts)\
          .with("ERROR: Failed to make dir #{dir} on all nodes")
        expect(RefArchSetup::BoltHelper.make_dir(dir, nodes)).to eq(false)
      end
    end
  end

  describe "run_cmd_with_bolt" do
    before do
      @expected_command = "bolt command run '#{cmd}' --nodes #{nodes}"
    end

    context "when bolt works and returns true" do
      it "returns true and outputs informative messages" do
        expected_output = "All Good"
        expected_status = 0
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(true) # rubocop:disable Style/SpecialGlobalVars
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts)\
          .with("Exit status was: #{expected_status}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")
        expect(RefArchSetup::BoltHelper.run_cmd_with_bolt(cmd, nodes)).to eq(true)
      end
    end

    context "when bolt fails and returns false" do
      it "returns false and outputs informative messages and errors" do
        expected_output = "No Good"
        expected_status = 1
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(false) # rubocop:disable Style/SpecialGlobalVars
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("ERROR: bolt command failed!")
        expect(RefArchSetup::BoltHelper).to receive(:puts)\
          .with("Exit status was: #{expected_status}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")
        expect(RefArchSetup::BoltHelper.run_cmd_with_bolt(cmd, nodes)).to eq(false)
      end
    end
  end

  describe "run_task_with_bolt" do
    before do
      @expected_command = "bolt task run #{task} VAR1=1 VAR2=2 --modulepath "\
      "#{RefArchSetup::RAS_MODULE_PATH} --nodes #{nodes}"
    end

    context "when bolt works and returns true" do
      expected_output = "All Good"
      expected_status = 0
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string) \
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(true) # rubocop:disable Style/SpecialGlobalVars
        allow(RefArchSetup::BoltHelper).to receive(:puts)
        expect(RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes)).to eq(true)
      end
      it "outputs informative messages" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string) \
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(true) # rubocop:disable Style/SpecialGlobalVars
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts)\
          .with("Exit status was: #{expected_status}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")
        RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes)
      end
    end

    context "when bolt fails and returns false" do
      expected_output = "No Good"
      expected_status = 1

      it "returns false" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string) \
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(false) # rubocop:disable Style/SpecialGlobalVars
        allow(RefArchSetup::BoltHelper).to receive(:puts)
        expect(RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes)).to eq(false)
      end
      it "returns false and outputs informative messages" do
        expect(RefArchSetup::BoltHelper).to receive(:params_to_string) \
          .with(params).and_return(params_str)
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(false) # rubocop:disable Style/SpecialGlobalVars
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("ERROR: bolt task failed!")
        expect(RefArchSetup::BoltHelper).to receive(:puts)\
          .with("Exit status was: #{expected_status}")
        RefArchSetup::BoltHelper.run_task_with_bolt(task, params, nodes)
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
      @expected_command = "bolt file upload #{source} #{destination} --nodes #{nodes}"
    end

    context "when bolt works and returns true" do
      it "returns true and outputs informative messages" do
        expected_output = "All Good"
        expected_status = 0
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(true) # rubocop:disable Style/SpecialGlobalVars
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts)\
          .with("Exit status was: #{expected_status}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")
        expect(RefArchSetup::BoltHelper.upload_file(source, destination, nodes)).to eq(true)
      end
    end

    context "when bolt fails and returns false" do
      it "returns false and outputs informative messages and errors" do
        expected_output = "No Good"
        expected_status = 1
        expect(RefArchSetup::BoltHelper).to receive(:`)\
          .with(@expected_command).and_return(expected_output)
        `(exit #{expected_status})`
        expect($?).to receive(:success?).and_return(false) # rubocop:disable Style/SpecialGlobalVars
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Running: #{@expected_command}")
        expect(RefArchSetup::BoltHelper).to receive(:puts)
          .with("ERROR: failed to upload file #{source} to #{destination} on #{nodes}")
        expect(RefArchSetup::BoltHelper).to receive(:puts)\
          .with("Exit status was: #{expected_status}")
        expect(RefArchSetup::BoltHelper).to receive(:puts).with("Output was: #{expected_output}")
        expect(RefArchSetup::BoltHelper.upload_file(source, destination, nodes)).to eq(false)
      end
    end
  end
end
