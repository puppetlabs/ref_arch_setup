require "spec_helper"

describe RefArchSetup::Install do
  let(:target_master)   { "local://localhost" }
  let(:pe_conf_path)    { "/tmp/pe.conf" }
  let(:pe_tarball_path) { "/tmp/pe.tarball" }
  let(:install)         { RefArchSetup::Install.new(target_master) }
  let(:task)            { "ref_arch_setup::install_pe" }
  let(:params)          do
    { "pe_conf_path" => pe_conf_path, "pe_tarball_path" => pe_tarball_path, \
      "pe_target_master" => target_master }
  end
  let(:params_str) do
    "pe_conf_path=#{pe_tarball_path} pe_tarball_path=#{pe_tarball_path} " \
      "pe_target_master=#{target_master}"
  end

  describe "initialize" do
    it "checks that the passed in parameters get used" do
      temp_install = RefArchSetup::Install.new(target_master)
      expect(temp_install.instance_variable_get("@target_master")).to eq(target_master)
    end
  end

  describe "bootstrap" do
    before do
      @expected_command = "bolt task run #{task} "
      @expected_command << params_str
      @expected_command << " --modulepath #{RefArchSetup::RAS_MODULE_PATH}"
      @expected_command << " --nodes #{target_master}"
    end

    context "when make_temp_dir and handle_pe_conf do not raise errors" do
      context "when called using default value" do
        context "when run_task_with_bolt returned true" do
          it "returns true" do
            expect(install).to receive(:make_tmp_work_dir).and_return(true)
            expect(install).to receive(:handle_pe_conf).and_return(true)
            expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
              .with(task, params, target_master)
              .and_return(true)
            expect(install.bootstrap(pe_conf_path, pe_tarball_path)).to eq(true)
          end
        end
      end

      context "when called passing in all values" do
        context "when run_task_with_bolt returned true" do
          it "returns true" do
            expect(install).to receive(:make_tmp_work_dir).and_return(true)
            expect(install).to receive(:handle_pe_conf).and_return(true)
            expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
              .with(task, params, target_master).and_return(true)
            expect(install.bootstrap(pe_conf_path, pe_tarball_path, target_master)).to eq(true)
          end
        end
        context "when run_task_with_bolt returned false" do
          it "returns false" do
            expect(install).to receive(:make_tmp_work_dir).and_return(true)
            expect(install).to receive(:handle_pe_conf).and_return(true)
            expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
              .with(task, params, target_master).and_return(false)
            expect(install.bootstrap(pe_conf_path, pe_tarball_path, target_master)).to eq(false)
          end
        end
      end
    end

    context "When make_tmp_dir raises an error" do
      it "should not be trapped" do
        expect(install).to receive(:make_tmp_work_dir).and_raise(RuntimeError)
        expect { install.bootstrap(pe_conf_path, pe_tarball_path, target_master) }.to \
          raise_error(RuntimeError)
      end
    end

    context "When handle_pe_conf raises an error" do
      it "should not be trapped" do
        expect(install).to receive(:make_tmp_work_dir).and_return(true)
        expect(install).to receive(:handle_pe_conf).and_raise(RuntimeError)
        expect { install.bootstrap(pe_conf_path, pe_tarball_path, target_master) }.to \
          raise_error(RuntimeError)
      end
    end
  end

  describe "handle_pe_conf" do
    context "When user did not give a pe.conf argument" do
      context "When pe.conf exists in the CWD" do
        it "it calls upload on it and returns true" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(Dir).to receive(:pwd).and_return(tmpdir)
          expect(File).to receive(:exist?).with(file_path).and_return(true)
          expect(install).to receive(:upload_pe_conf).with(file_path).and_return(true)
          expect(install.handle_pe_conf(nil)).to eq(true)
        end
      end
      context "When pe.conf does not exist in the CWD" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(Dir).to receive(:pwd).and_return(tmpdir)
          expect(File).to receive(:exist?).with(file_path).and_return(false)
          expect { install.handle_pe_conf(nil) }.to \
            raise_error(RuntimeError, /No pe.conf file found in current working directory/)
        end
      end
    end
    context "When user gave a value for pe.conf that is a directory" do
      context "When a pe.conf is found in the dir" do
        it "calls upload on it and returns true" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(tmpdir).and_return(tmpdir)
          expect(File).to receive(:directory?).with(tmpdir).and_return(true)
          expect(File).to receive(:exist?).with(file_path).and_return(true)
          expect(install).to receive(:upload_pe_conf).with(file_path).and_return(true)
          expect(install.handle_pe_conf(tmpdir)).to eq(true)
        end
      end
      context "When a pe.conf is NOT found in the dir" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(tmpdir).and_return(tmpdir)
          expect(File).to receive(:directory?).with(tmpdir).and_return(true)
          expect(File).to receive(:exist?).with(file_path).and_return(false)
          expect { install.handle_pe_conf(tmpdir) }.to \
            raise_error(RuntimeError, /No pe.conf file found in directory: #{tmpdir}/)
        end
      end
    end
    context "When user gave a value that is not a directory" do
      context "When the file is found" do
        it "calls upload on it and returns true" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(file_path).and_return(file_path)
          expect(File).to receive(:directory?).with(file_path).and_return(false)
          expect(File).to receive(:exist?).with(file_path).and_return(true)
          expect(install).to receive(:upload_pe_conf).with(file_path).and_return(true)
          expect(install.handle_pe_conf(file_path)).to eq(true)
        end
      end
      context "When the file is NOT found" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(file_path).and_return(file_path)
          expect(File).to receive(:directory?).with(file_path).and_return(false)
          expect(File).to receive(:exist?).with(file_path).and_return(false)
          expect { install.handle_pe_conf(file_path) }.to \
            raise_error(RuntimeError, /pe.conf file not found #{file_path}/)
        end
      end
    end
  end

  describe "make_tmp_work_dir" do
    context "with defaults and make_dir returns true" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:make_dir)\
          .with(RefArchSetup::TMP_WORK_DIR, target_master).and_return(true)
        expect(install.make_tmp_work_dir).to eq(true)
      end
    end

    context "with option values passed in and make_dir returns true" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:make_dir)\
          .with(RefArchSetup::TMP_WORK_DIR, target_master).and_return(true)
        expect(install.make_tmp_work_dir(target_master)).to eq(true)
      end
    end

    context "with option values passed in and make_dir returns false" do
      it "returns false" do
        expect(RefArchSetup::BoltHelper).to receive(:make_dir)\
          .with(RefArchSetup::TMP_WORK_DIR, target_master).and_return(false)
        expect(install.make_tmp_work_dir(target_master)).to eq(false)
      end
    end
  end

  describe "upload_pe_conf" do
    context "with defaults and upload_file returns true" do
      it "returns true" do
        src = "#{RefArchSetup::RAS_FIXTURES_PATH}/pe.conf"
        dest = "#{RefArchSetup::TMP_WORK_DIR}/pe.conf"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)\
          .with(src, dest, target_master).and_return(true)
        expect(install.upload_pe_conf).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns true" do
      it "returns true" do
        src = pe_conf_path
        dest = "/tmp/foo"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)\
          .with(src, dest, target_master).and_return(true)
        expect(install.upload_pe_conf(src, dest, target_master)).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns false" do
      it "returns false" do
        src = pe_conf_path
        dest = "/tmp/foo"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)\
          .with(src, dest, target_master).and_return(false)
        expect(install.upload_pe_conf(src, dest, target_master)).to eq(false)
      end
    end
  end

  describe "upload_pe_tarball" do
    context "with defaults and upload_file returns true" do
      it "returns true" do
        src = "/tmp/foo.tar"
        dest = "#{RefArchSetup::TMP_WORK_DIR}/foo.tar"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)\
          .with(src, dest, target_master).and_return(true)
        expect(install.upload_pe_tarball(src)).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns true" do
      it "returns true" do
        src = "/tmp/foo.tar"
        dest = "/tmp/foo"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)\
          .with(src, dest, target_master).and_return(true)
        expect(install.upload_pe_tarball(src, dest, target_master)).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns false" do
      it "returns false" do
        src = "/tmp/foo.tar"
        dest = "/tmp/foo"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)\
          .with(src, dest, target_master).and_return(false)
        expect(install.upload_pe_tarball(src, dest, target_master)).to eq(false)
      end
    end
  end
end
