require "spec_helper"

describe RefArchSetup::Install do
  # let(:target_master) { "local://localhost" }

  let(:target_master) { "local://localhost" }

  let(:remote_target_master) { "remote.target.master" }
  let(:pe_conf_path) { "/tmp/pe.conf" }
  let(:conf_path_on_master) { "#{tmp_work_dir}/pe.conf" }
  let(:pe_tarball_filename) { "pe.tarball.tar" }
  let(:pe_tarball) { "/tmp/#{pe_tarball_filename}" }
  let(:pe_version_latest) { "latest" }
  let(:pe_version_number) { "2018.1.4" }
  let(:tmp_work_dir) { "/tmp/ref_arch_setup" }
  let(:tarball_path_on_master) { "#{tmp_work_dir}/#{pe_tarball_filename}" }
  let(:install) { RefArchSetup::Install.new(target_master) }
  let(:install_task_params) do
    { "pe_conf_path" => conf_path_on_master, "pe_tarball_path" => tarball_path_on_master }
  end
  let(:pe_tarball_url) { "https://test.net/2018.1/#{pe_tarball_filename}" }
  let(:pe_tarball_http_url) { "http://test.net/2018.1/#{pe_tarball_filename}" }
  let(:download_task_params) do
    { "url" => pe_tarball_url, "destination" => tmp_work_dir }
  end

  let(:test_uri) { Class.new }
  let(:bolt_output_success) { "Bolt command was successful" }
  let(:bolt_output_failure) { "Bolt command failed!" }

  describe "#initialize" do
    it "checks that the passed in parameters get used" do
      temp_install = RefArchSetup::Install.new(target_master)
      expect(temp_install.instance_variable_get("@target_master")).to eq(target_master)
    end
  end

  describe "#bootstrap" do
    context "when a tarball is specified" do
      context "when a version is not specified" do
        it "uses the specified tarball" do
          message = "Proceeding with specified pe_tarball: #{pe_tarball}"

          expect(install).to receive(:puts).with(message)
          expect(RefArchSetup::DownloadHelper).not_to receive(:build_prod_tarball_url)

          expect(install).to receive(:make_tmp_work_dir).and_return(true)
          expect(install).to receive(:handle_pe_conf).and_return(conf_path_on_master)
          expect(install).to receive(:handle_pe_tarball).and_return(tarball_path_on_master)
          expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
            .with(RefArchSetup::INSTALL_PE_TASK, install_task_params, target_master)
            .and_return(bolt_output_success)

          install.bootstrap(pe_conf_path, pe_tarball, nil)
        end
      end

      context "when a version is specified" do
        it "still uses the specified tarball" do
          message = "Proceeding with specified pe_tarball: #{pe_tarball}"

          expect(install).to receive(:puts).with(message)
          expect(RefArchSetup::DownloadHelper).not_to receive(:build_prod_tarball_url)

          expect(install).to receive(:make_tmp_work_dir).and_return(true)
          expect(install).to receive(:handle_pe_conf).and_return(conf_path_on_master)
          expect(install).to receive(:handle_pe_tarball).and_return(tarball_path_on_master)
          expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
            .with(RefArchSetup::INSTALL_PE_TASK, install_task_params, target_master)
            .and_return(bolt_output_success)

          install.bootstrap(pe_conf_path, pe_tarball, "2077.1.4")
        end
      end
    end

    context "when a version is specified without a tarball" do
      it "uses the specified version" do
        message = "Proceeding with specified pe_version: #{pe_version_number}"

        expect(install).to receive(:puts).with(message)
        expect(RefArchSetup::DownloadHelper).to receive(:build_prod_tarball_url)
          .with(pe_version_number, target_master).and_return(pe_tarball_url)

        expect(install).to receive(:make_tmp_work_dir).and_return(true)
        expect(install).to receive(:handle_pe_conf).and_return(conf_path_on_master)
        expect(install).to receive(:handle_pe_tarball)
          .with(pe_tarball_url).and_return(tarball_path_on_master)

        expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
          .with(RefArchSetup::INSTALL_PE_TASK, install_task_params, target_master)
          .and_return(bolt_output_success)

        install.bootstrap(pe_conf_path, nil, pe_version_number)
      end
    end

    context "when neither a tarball or version is specified" do
      it "raises an error" do
        error = "Either a pe_version or pe_tarball must be specified"

        expect { install.bootstrap(pe_conf_path, nil, nil) }
          .to raise_error(RuntimeError, error)
      end
    end

    context "when setup methods do not raise errors" do
      context "when run_task_with_bolt returns output" do
        it "returns true" do
          allow(install).to receive(:puts)

          expect(install).to receive(:make_tmp_work_dir).and_return(true)
          expect(install).to receive(:handle_pe_conf).and_return(conf_path_on_master)
          expect(install).to receive(:handle_pe_tarball).and_return(tarball_path_on_master)
          expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
            .with(RefArchSetup::INSTALL_PE_TASK, install_task_params, target_master)
            .and_return(bolt_output_success)
          expect(install.bootstrap(pe_conf_path, pe_tarball, nil)).to eq(true)
        end
      end

      context "when run_task_with_bolt raises an error" do
        it "does not trap the error" do
          allow(install).to receive(:puts)

          expect(install).to receive(:make_tmp_work_dir).and_return(true)
          expect(install).to receive(:handle_pe_conf).and_return(conf_path_on_master)
          expect(install).to receive(:handle_pe_tarball).and_return(tarball_path_on_master)
          expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
            .with(RefArchSetup::INSTALL_PE_TASK, install_task_params, target_master)
            .and_raise(RuntimeError)
          expect { install.bootstrap(pe_conf_path, pe_tarball, nil) }
            .to raise_error(RuntimeError)
        end
      end
    end

    context "When make_tmp_dir raises an error" do
      it "does not trap the error" do
        allow(install).to receive(:puts)

        expect(install).to receive(:make_tmp_work_dir).and_raise(RuntimeError)
        expect { install.bootstrap(pe_conf_path, pe_tarball, nil) }.to raise_error(RuntimeError)
      end
    end

    context "When handle_pe_conf raises an error" do
      it "does not trap the error" do
        allow(install).to receive(:puts)

        expect(install).to receive(:make_tmp_work_dir).and_return(true)
        expect(install).to receive(:handle_pe_conf).and_raise(RuntimeError)
        expect { install.bootstrap(pe_conf_path, pe_tarball, nil) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe "#handle_pe_conf_path" do
    context "When user gave a value for pe.conf that is a directory" do
      context "When a pe.conf is found in the dir" do
        it "returns the file path" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(tmpdir).and_return(tmpdir)
          expect(File).to receive(:directory?).with(tmpdir).and_return(true)
          expect(File).to receive(:exist?).with(file_path).and_return(true)
          expect(install.handle_pe_conf_path(tmpdir)).to eq(file_path)
        end
      end
      context "When a pe.conf is NOT found in the dir" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(tmpdir).and_return(tmpdir)
          expect(File).to receive(:directory?).with(tmpdir).and_return(true)
          expect(File).to receive(:exist?).with(file_path).and_return(false)
          expect { install.handle_pe_conf_path(tmpdir) }
            .to raise_error(RuntimeError, /No pe.conf file found in directory: #{tmpdir}/)
        end
      end
    end
    context "When user gave a value that is not a directory" do
      context "When the file is found" do
        it "returns the file path" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(file_path).and_return(file_path)
          expect(File).to receive(:directory?).with(file_path).and_return(false)
          expect(File).to receive(:basename).with(file_path).and_return("pe.conf")
          expect(File).to receive(:exist?).with(file_path).and_return(true)
          expect(install.handle_pe_conf_path(file_path)).to eq(file_path)
        end
      end
      context "When the file is NOT found" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(File).to receive(:expand_path).with(file_path).and_return(file_path)
          expect(File).to receive(:directory?).with(file_path).and_return(false)
          expect(File).to receive(:basename).with(file_path).and_return("pe.conf")
          expect(File).to receive(:exist?).with(file_path).and_return(false)
          expect { install.handle_pe_conf_path(file_path) }
            .to raise_error(RuntimeError, /pe.conf file not found #{file_path}/)
        end
      end
    end

    context "When the file is not named pe.conf" do
      it "raises an error" do
        tmpdir = "/tmp/foo"
        file_path = "#{tmpdir}/not_pe.conf"
        expect(File).to receive(:expand_path).with(file_path).and_return(file_path)
        expect(File).to receive(:directory?).with(file_path).and_return(false)
        expect(File).to receive(:basename).with(file_path).and_return("not_pe.conf")
        expect(File).not_to receive(:exist?)
        expect(install).not_to receive(:upload_pe_conf)
        expect { install.handle_pe_conf_path(file_path) }
          .to raise_error(RuntimeError, /Specified file is not named pe.conf/)
      end
    end
  end

  describe "#handle_pe_conf" do
    context "When user did not give a pe.conf argument" do
      context "When pe.conf exists in the CWD" do
        it "it calls upload on it and returns true" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(Dir).to receive(:pwd).and_return(tmpdir)
          expect(File).to receive(:exist?).with(file_path).and_return(true)
          expect(install).to receive(:upload_pe_conf).with(file_path).and_return(true)
          expect(install.handle_pe_conf(nil)).to eq(conf_path_on_master)
        end
      end
      context "When pe.conf does not exist in the CWD" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(Dir).to receive(:pwd).and_return(tmpdir)
          expect(File).to receive(:exist?).with(file_path).and_return(false)
          expect { install.handle_pe_conf(nil) }
            .to raise_error(RuntimeError, /No pe.conf file found in current working directory/)
        end
      end
    end
    context "When user gave a value for pe.conf that is a directory" do
      context "When a pe.conf is found in the dir" do
        it "calls upload on it and returns true" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(install).to receive(:handle_pe_conf_path).with(tmpdir).and_return(file_path)
          expect(install).to receive(:upload_pe_conf).with(file_path).and_return(true)
          expect(install.handle_pe_conf(tmpdir)).to eq(conf_path_on_master)
        end
      end
      context "When a pe.conf is NOT found in the dir" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          expect(install).to receive(:handle_pe_conf_path).with(tmpdir).and_raise(RuntimeError)

          expect(install).not_to receive(:upload_pe_conf)
          expect { install.handle_pe_conf(tmpdir) }.to raise_error(RuntimeError)
        end
      end
    end
    context "When user gave a value that is not a directory" do
      context "When the file is found" do
        it "calls upload on it and returns true" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"
          expect(install).to receive(:handle_pe_conf_path).with(file_path).and_return(file_path)
          expect(install).to receive(:upload_pe_conf).with(file_path).and_return(true)
          expect(install.handle_pe_conf(file_path)).to eq(conf_path_on_master)
        end
      end
      context "When the file is NOT found" do
        it "raises an error" do
          tmpdir = "/tmp/foo"
          file_path = "#{tmpdir}/pe.conf"

          expect(install).to receive(:handle_pe_conf_path)
            .with(file_path).and_raise(RuntimeError)

          expect(install).not_to receive(:upload_pe_conf)
          expect { install.handle_pe_conf(file_path) }.to raise_error(RuntimeError)
        end
      end
    end
    context "When the upload is not successful" do
      it "raises an error" do
        tmpdir = "/tmp/foo"
        file_path = "#{tmpdir}/pe.conf"
        expect(install).to receive(:handle_pe_conf_path).with(file_path).and_return(file_path)
        expect(install).to receive(:upload_pe_conf).with(file_path).and_return(false)
        expect { install.handle_pe_conf(file_path) }
          .to raise_error(RuntimeError, /Unable to upload pe.conf file to #{target_master}/)
      end
    end
    context "When the file is not named pe.conf" do
      it "raises an error" do
        tmpdir = "/tmp/foo"
        file_path = "#{tmpdir}/not_pe.conf"

        expect(install).to receive(:handle_pe_conf_path).with(file_path).and_raise(RuntimeError)

        expect(install).not_to receive(:upload_pe_conf)
        expect { install.handle_pe_conf(file_path) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#valid_url?" do
    context "when given a url starting with http" do
      it "returns true" do
        expect(install.valid_url?(pe_tarball_http_url)).to eq(true)
      end
    end

    context "when given a url starting with https" do
      it "returns true" do
        expect(install.valid_url?(pe_tarball_url)).to eq(true)
      end
    end

    context "when given an invalid url" do
      it "returns false" do
        expect(install.valid_url?(pe_tarball)).to eq(false)
      end
    end
  end

  describe "#validate_tarball_extension" do
    context "when given a path ending with .tar" do
      it "returns true" do
        expect(install.validate_tarball_extension(pe_tarball)).to eq(true)
      end
    end

    context "when given a url ending with .tar" do
      it "returns true" do
        expect(install.validate_tarball_extension(pe_tarball_url)).to eq(true)
      end
    end

    context "when given a path ending with .tar.gz" do
      it "returns true" do
        expect(install.validate_tarball_extension("#{pe_tarball}.gz")).to eq(true)
      end
    end

    context "when given a url ending with .tar.gz" do
      it "returns true" do
        expect(install.validate_tarball_extension("#{pe_tarball_url}.gz")).to eq(true)
      end
    end

    context "when given a path not ending in .tar or .tar.gz" do
      it "raises an error" do
        path = "/tmp/file.txt"
        expect { install.validate_tarball_extension(path) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#parse_url" do
    context "when given a valid url" do
      it "sets the instance variables and returns true" do
        # TODO: verify instance variables
        expect(install.parse_url(pe_tarball_url)).to eq(true)
      end
    end

    context "when given an invalid url" do
      it "raises an error" do
        expect { install.parse_url(nil) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#target_master_is_localhost?" do
    context "when the target master is localhost" do
      it "returns true" do
        install.instance_variable_set(:@target_master, target_master)
        expect(install.target_master_is_localhost?).to eq(true)
      end
    end

    context "when the target master is not localhost" do
      it "returns false" do
        install.instance_variable_set(:@target_master, remote_target_master)
        expect(install.target_master_is_localhost?).to eq(false)
      end
    end
  end

  describe "#file_exist_on_target_master?" do
    before do
      @command = "[ -f #{pe_tarball} ]"
    end

    context "when the file exists on the target master" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)
          .with(@command, target_master).and_return(bolt_output_success)
        expect(install.file_exist_on_target_master?(pe_tarball)).to eq(true)
      end
    end

    context "when the file does not exist on the target master" do
      it "returns false" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)
          .with(@command, target_master).and_raise(RuntimeError)
        expect(install.file_exist_on_target_master?(pe_tarball)).to eq(false)
      end
    end
  end

  describe "#download_pe_tarball" do
    context "when the download is successful" do
      it "returns true" do
        allow(install).to receive(:puts)
        expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
          .with(RefArchSetup::DOWNLOAD_PE_TARBALL_TASK, download_task_params, target_master)
          .and_return(true)
        expect(install.download_pe_tarball(pe_tarball_url, target_master)).to eq(true)
      end
    end

    context "when the download is not successful" do
      it "does not trap the error" do
        allow(install).to receive(:puts)
        expect(RefArchSetup::BoltHelper).to receive(:run_task_with_bolt)
          .with(RefArchSetup::DOWNLOAD_PE_TARBALL_TASK, download_task_params, target_master)
          .and_raise(RuntimeError)
        expect { install.download_pe_tarball(pe_tarball_url, target_master) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe "#download_and_move_pe_tarball" do
    before do
      install.instance_variable_set(:@pe_tarball_filename, pe_tarball_filename)
      install.instance_variable_set(:@target_master, remote_target_master)
    end
    context "when the download is successful" do
      context "when the upload is successful" do
        it "returns true" do
          allow(install).to receive(:puts)
          expect(install).to receive(:download_pe_tarball)
            .with(pe_tarball_url, "localhost").and_return(true)
          expect(install).to receive(:upload_pe_tarball)
            .with(tarball_path_on_master).and_return(true)
          expect(install.download_and_move_pe_tarball(pe_tarball_url)).to eq(true)
        end
      end

      context "when the upload is not successful" do
        it "returns false" do
          allow(install).to receive(:puts)
          expect(install).to receive(:download_pe_tarball)
            .with(pe_tarball_url, "localhost").and_return(true)
          expect(install).to receive(:upload_pe_tarball)
            .with(tarball_path_on_master).and_return(false)
          expect(install.download_and_move_pe_tarball(pe_tarball_url)).to eq(false)
        end
      end
    end

    context "when the download is not successful" do
      it "does not attempt to upload and returns false" do
        allow(install).to receive(:puts)
        expect(install).to receive(:download_pe_tarball).with(pe_tarball_url, "localhost")
                                                        .and_return(false)
        expect(install).not_to receive(:upload_pe_tarball)
        expect(install.download_and_move_pe_tarball(pe_tarball_url)).to eq(false)
      end
    end
  end

  describe "#handle_tarball_url" do
    context "when the url is successfully parsed" do
      before do
        install.instance_variable_set(:@pe_tarball_filename, pe_tarball_filename)
      end

      context "when the target master is localhost" do
        before do
          install.instance_variable_set(:@target_master, target_master)
        end

        context "when the download is successful" do
          it "returns the tarball path on the target master" do
            # TODO: handle instance variable

            expect(install).to receive(:parse_url).with(pe_tarball_url).and_return(true)
            expect(install).to receive(:target_master_is_localhost?).and_return(true)
            expect(install).to receive(:download_pe_tarball).with(pe_tarball_url, "localhost")
                                                            .and_return(true)
            expect(install).not_to receive(:download_and_move_pe_tarball)
            expect(install.handle_tarball_url(pe_tarball_url)).to eq(tarball_path_on_master)
          end
        end

        context "when the download is not successful" do
          it "raises an error" do
            expect(install).to receive(:parse_url).with(pe_tarball_url).and_return(true)
            expect(install).to receive(:target_master_is_localhost?).and_return(true)
            expect(install).to receive(:download_pe_tarball)
              .with(pe_tarball_url, "localhost").and_return(false)
            expect { install.handle_tarball_url(pe_tarball_url) }.to raise_error(RuntimeError)
          end
        end
      end

      context "when the target master is not localhost" do
        before do
          install.instance_variable_set(:@target_master, remote_target_master)
        end

        context "when the download is successful" do
          it "doesn't attempt to move the tarball, returns the tarball path on the target master" do
            expect(install).to receive(:parse_url).with(pe_tarball_url).and_return(true)
            expect(install).to receive(:target_master_is_localhost?).and_return(false)
            allow(install).to receive(:puts)

            expect(install).to receive(:download_pe_tarball)
              .with(pe_tarball_url, remote_target_master)
              .and_return(true)

            expect(install).not_to receive(:download_and_move_pe_tarball)

            expect(install.handle_tarball_url(pe_tarball_url)).to eq(tarball_path_on_master)
          end
        end

        context "when the download is not successful" do
          context "when the subsequent download and move is successful" do
            it "does not raise an error and returns the filename" do
              expect(install).to receive(:parse_url).with(pe_tarball_url).and_return(true)
              expect(install).to receive(:target_master_is_localhost?).and_return(false)

              allow(install).to receive(:puts)

              expect(install).to receive(:download_pe_tarball)
                .with(pe_tarball_url, remote_target_master)
                .and_raise(RuntimeError)

              expect(install).to receive(:download_and_move_pe_tarball)
                .with(pe_tarball_url)
                .and_return(true)

              expect(install.handle_tarball_url(pe_tarball_url))
                .to eq(tarball_path_on_master)
            end
          end

          context "when the subsequent download and move is not successful" do
            it "raises an error" do
              error_a = "download_pe_tarball failed"
              error_b = "download_and_move_pe_tarball"
              remote_error = "Failed downloading #{pe_tarball_url} to localhost and moving to #{remote_target_master}"

              expect(install).to receive(:parse_url).with(pe_tarball_url).and_return(true)
              expect(install).to receive(:target_master_is_localhost?).and_return(false)

              allow(install).to receive(:puts)

              expect(install).to receive(:download_pe_tarball)
                .with(pe_tarball_url, remote_target_master)
                .and_raise(RuntimeError, error_a)

              expect(install).to receive(:download_and_move_pe_tarball)
                .with(pe_tarball_url)
                .and_return(false)

              expect { install.handle_tarball_url(pe_tarball_url) }
                .to raise_error(RuntimeError, remote_error)
            end
          end
        end
      end
    end

    context "when parse_url raises an error" do
      it "does not trap the error" do
        expect(install).to receive(:parse_url).with("http:// 123").and_raise(RuntimeError)

        expect { install.handle_tarball_url("http:// 123") }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe "#copy_pe_tarball_on_target_master" do
    before do
      @command = "cp #{pe_tarball} #{tmp_work_dir}"
    end

    context "when the file is copied successfully" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)
          .with(@command, target_master)
          .and_return(bolt_output_success)
        expect(install.copy_pe_tarball_on_target_master(pe_tarball)).to eq(true)
      end
    end

    context "when the file is not copied successfully" do
      it "does not trap the error" do
        expect(RefArchSetup::BoltHelper).to receive(:run_cmd_with_bolt)
          .with(@command, target_master)
          .and_raise(RuntimeError)
        expect { install.copy_pe_tarball_on_target_master(pe_tarball) }
          .to raise_error(RuntimeError)
      end
    end

    context "when the specified file is already in the TMP_WORK_DIR" do
      it "returns true" do
        message = "Not copying the tarball as the source and destination are the same"
        tarball = "#{tmp_work_dir}/#{pe_tarball_filename}"

        expect(install).to receive(:puts).with(message)
        expect(RefArchSetup::BoltHelper).not_to receive(:run_cmd_with_bolt)

        expect(install.copy_pe_tarball_on_target_master(tarball)).to eq(true)
      end
    end
  end

  describe "#handle_tarball_path_with_remote_target_master" do
    before do
      install.instance_variable_set(:@target_master, remote_target_master)
      @remote_flag = "#{remote_target_master}:"
      @remote_tarball_path = @remote_flag + pe_tarball
    end
    context "when the tarball path is on the master" do
      context "when the file exists" do
        it "copies the file to the tmp working dir and returns true" do
          expect(@remote_tarball_path).to receive(:start_with?).with(@remote_flag).and_return(true)

          expect(@remote_tarball_path).to receive(:sub!)
            .with(@remote_flag, "").and_return(pe_tarball)

          expect(install).to receive(:file_exist_on_target_master?)
            .with(pe_tarball).and_return(true)

          expect(install).to receive(:copy_pe_tarball_on_target_master)
            .with(pe_tarball).and_return(true)

          expect(install.handle_tarball_path_with_remote_target_master(@remote_tarball_path))
            .to eq(true)
        end
      end

      context "when the file does not exist" do
        it "does not copy the file and returns false" do
          expect(@remote_tarball_path).to receive(:start_with?).with(@remote_flag)
                                                               .and_return(true)

          expect(@remote_tarball_path).to receive(:sub!).with(@remote_flag, "")
                                                        .and_return(pe_tarball)

          expect(install).to receive(:file_exist_on_target_master?)
            .with(pe_tarball).and_return(false)

          expect(install).not_to receive(:copy_pe_tarball_on_target_master)

          # TODO: rubocop Metrics/LineLength?
          expect(install.handle_tarball_path_with_remote_target_master(@remote_tarball_path))
            .to eq(false)
        end
      end
    end

    context "when the tarball path is not on the master" do
      context "when the file exists" do
        it "uploads the file to the tmp working dir and returns true" do
          expect(pe_tarball).to receive(:start_with?).with(@remote_flag)
                                                     .and_return(false)

          expect(install).not_to receive(:file_exist_on_target_master?)
          expect(install).not_to receive(:copy_pe_tarball_on_target_master)

          expect(File).to receive(:exist?).with(pe_tarball).and_return(true)
          expect(install).to receive(:upload_pe_tarball)
            .with(pe_tarball).and_return(true)

          expect(install.handle_tarball_path_with_remote_target_master(pe_tarball))
            .to eq(true)
        end
      end

      context "when the file does not exist" do
        it "does not upload the file and raises an error" do
          expect(pe_tarball).to receive(:start_with?)
            .with(@remote_flag).and_return(false)

          expect(install).not_to receive(:file_exist_on_target_master?)
          expect(install).not_to receive(:copy_pe_tarball_on_target_master)

          expect(File).to receive(:exist?).with(pe_tarball).and_return(false)
          expect(install).not_to receive(:upload_pe_tarball)

          expect { install.handle_tarball_path_with_remote_target_master(pe_tarball) }
            .to raise_error(RuntimeError, "File not found: #{pe_tarball}")
        end
      end
    end
  end

  describe "#handle_tarball_path" do
    context "when the target master is localhost" do
      before do
        install.instance_variable_set(:@target_master, target_master)
      end

      context "when the tarball exists" do
        context "when the upload is successful" do
          it "returns the filename" do
            expect(File).to receive(:basename).with(pe_tarball).and_return(pe_tarball_filename)
            expect(install).to receive(:target_master_is_localhost?).and_return(true)

            expect(File).to receive(:exist?).with(pe_tarball).and_return(true)
            expect(install).to receive(:upload_pe_tarball)
              .with(pe_tarball).and_return(true)
            expect(install.handle_tarball_path(pe_tarball)).to eq(tarball_path_on_master)
          end
        end

        context "when the upload is not successful" do
          it "raises the expected error" do
            copy_error = "Unable to copy tarball to the RAS working directory on #{target_master}"

            expect(File).to receive(:basename).with(pe_tarball).and_return(pe_tarball_filename)
            expect(install).to receive(:target_master_is_localhost?).and_return(true)
            expect(File).to receive(:exist?).with(pe_tarball).and_return(true)
            expect(install).to receive(:upload_pe_tarball)
              .with(pe_tarball).and_return(false)

            expect { install.handle_tarball_path(pe_tarball) }
              .to raise_error(RuntimeError, copy_error)
          end
        end
      end

      context "when the tarball does not exist" do
        it "raises the expected error" do
          file_not_found_error = "File not found: #{pe_tarball}"

          expect(File).to receive(:basename).with(pe_tarball).and_return(pe_tarball_filename)
          expect(install).to receive(:target_master_is_localhost?).and_return(true)
          expect(File).to receive(:exist?).with(pe_tarball).and_return(false)
          expect(install).not_to receive(:upload_pe_tarball)
          expect { install.handle_tarball_path(pe_tarball) }
            .to raise_error(RuntimeError, file_not_found_error)
        end
      end
    end

    context "when the target master is not localhost" do
      before do
        install.instance_variable_set(:@target_master, remote_target_master)
      end

      context "when the tarball is handled successfully" do
        it "returns the filename" do
          expect(File).to receive(:basename).with(pe_tarball).and_return(pe_tarball_filename)
          expect(install).to receive(:target_master_is_localhost?).and_return(false)

          expect(install).to receive(:handle_tarball_path_with_remote_target_master)
            .with(pe_tarball).and_return(true)

          expect(install.handle_tarball_path(pe_tarball))
            .to eq(tarball_path_on_master)
        end
      end

      context "when the tarball is not handled successfully" do
        it "raises the expected error" do
          upload_error = "Unable to upload tarball to the RAS working directory on #{remote_target_master}"

          expect(File).to receive(:basename).with(pe_tarball).and_return(pe_tarball_filename)
          expect(install).to receive(:target_master_is_localhost?).and_return(false)

          expect(install).to receive(:handle_tarball_path_with_remote_target_master)
            .with(pe_tarball).and_return(false)

          expect { install.handle_tarball_path(pe_tarball) }
            .to raise_error(RuntimeError, upload_error)
        end
      end
    end
  end

  describe "#handle_pe_tarball" do
    context "when the extension is valid" do
      context "when the tarball path is a valid URL" do
        context "when the tarball URL is handled successfully" do
          it "returns the tarball path on the master" do
            expect(install).to receive(:validate_tarball_extension)
              .with(pe_tarball_url).and_return(true)
            expect(install).to receive(:valid_url?).with(pe_tarball_url).and_return(true)
            expect(install).to receive(:handle_tarball_url)
              .with(pe_tarball_url).and_return(tarball_path_on_master)

            expect(install.handle_pe_tarball(pe_tarball_url))
              .to eq(tarball_path_on_master)
          end
        end

        context "when the tarball URL is not handled successfully" do
          it "raises an error" do
            expect(install).to receive(:validate_tarball_extension)
              .with(pe_tarball_url).and_return(true)
            expect(install).to receive(:valid_url?).with(pe_tarball_url).and_return(true)
            expect(install).to receive(:handle_tarball_url).with(pe_tarball_url).and_return(nil)

            expect { install.handle_pe_tarball(pe_tarball_url) }
              .to raise_error(RuntimeError)
          end
        end
      end

      context "when the tarball path is not a valid URL and a path is assumed" do
        context "when the tarball path is handled successfully" do
          it "returns the tarball path on the master" do
            expect(install).to receive(:validate_tarball_extension)
              .with(pe_tarball).and_return(true)
            expect(install).to receive(:valid_url?).with(pe_tarball).and_return(false)
            expect(install).to receive(:handle_tarball_path)
              .with(pe_tarball).and_return(tarball_path_on_master)

            expect(install.handle_pe_tarball(pe_tarball))
              .to eq(tarball_path_on_master)
          end
        end

        context "when the tarball path is not handled successfully" do
          it "raises an error" do
            expect(install).to receive(:validate_tarball_extension)
              .with(pe_tarball).and_return(true)
            expect(install).to receive(:valid_url?).with(pe_tarball).and_return(false)
            expect(install).to receive(:handle_tarball_path).with(pe_tarball).and_return(nil)

            expect { install.handle_pe_tarball(pe_tarball) }
              .to raise_error(RuntimeError)
          end
        end
      end
    end

    context "when the extension is not valid" do
      it "raises an error" do
        path = "/tmp/invalid"
        expect(install).to receive(:validate_tarball_extension).with(path).and_raise(RuntimeError)
        expect { install.handle_pe_tarball(path) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe "#make_tmp_work_dir" do
    context "with defaults and make_dir returns true" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:make_dir)
          .with(RefArchSetup::TMP_WORK_DIR, target_master).and_return(true)
        expect(install.make_tmp_work_dir).to eq(true)
      end
    end

    context "with option values passed in and make_dir returns true" do
      it "returns true" do
        expect(RefArchSetup::BoltHelper).to receive(:make_dir)
          .with(RefArchSetup::TMP_WORK_DIR, target_master).and_return(true)
        expect(install.make_tmp_work_dir).to eq(true)
      end
    end

    context "with option values passed in and make_dir raises an error" do
      it "does not trap the error" do
        expect(RefArchSetup::BoltHelper).to receive(:make_dir)
          .with(RefArchSetup::TMP_WORK_DIR, target_master).and_raise(RuntimeError)
        expect { install.make_tmp_work_dir }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#upload_pe_conf" do
    context "with defaults and upload_file returns output" do
      it "returns true" do
        src = "#{RefArchSetup::RAS_FIXTURES_PATH}/pe.conf"
        dest = "#{RefArchSetup::TMP_WORK_DIR}/pe.conf"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_return(bolt_output_success)
        expect(install.upload_pe_conf).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns output" do
      it "returns true" do
        src = pe_conf_path
        dest = "/tmp/foo"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_return(bolt_output_success)
        expect(install.upload_pe_conf(src, dest, target_master)).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns nil" do
      it "returns false" do
        src = pe_conf_path
        dest = "/tmp/foo"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_return(nil)
        expect(install.upload_pe_conf(src, dest, target_master)).to eq(false)
      end
    end

    context "with option values passed in and upload_file raises an error" do
      it "does not trap the error" do
        src = pe_conf_path
        dest = "/tmp/foo"
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_raise(RuntimeError)
        expect { install.upload_pe_conf(src, dest, target_master) }
          .to raise_error(RuntimeError)
      end
    end
  end

  describe "#upload_pe_tarball" do
    context "with defaults and upload_file returns output" do
      it "returns true" do
        src = "/tmp/foo.tar"
        dest = "#{RefArchSetup::TMP_WORK_DIR}/foo.tar"
        message = "Attempting upload from #{src} to #{dest} on #{target_master}"
        expected_output = "All Good"

        expect(install).to receive(:puts).with(message)
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_return(expected_output)
        expect(install.upload_pe_tarball(src)).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns output" do
      it "returns true" do
        src = pe_tarball
        dest = tarball_path_on_master
        message = "Attempting upload from #{src} to #{dest} on #{target_master}"
        expected_output = "All Good"

        expect(install).to receive(:puts).with(message)
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_return(expected_output)
        expect(install.upload_pe_tarball(src)).to eq(true)
      end
    end

    context "with option values passed in and upload_file returns nil" do
      it "returns true" do
        src = pe_tarball
        dest = tarball_path_on_master
        message = "Attempting upload from #{src} to #{dest} on #{target_master}"
        expected_output = "All Good"

        expect(install).to receive(:puts).with(message)
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_return(nil)
        expect(install.upload_pe_tarball(src)).to eq(false)
      end
    end

    context "with option values passed in and upload_file raises an error" do
      it "does not trap the error" do
        src = pe_tarball
        dest = tarball_path_on_master
        message = "Attempting upload from #{src} to #{dest} on #{target_master}"
        error = "Upload failed!!!"
        expect(install).to receive(:puts).with(message)
        expect(RefArchSetup::BoltHelper).to receive(:upload_file)
          .with(src, dest, target_master).and_raise(RuntimeError, error)

        expect { install.upload_pe_tarball(src) }.to raise_error(RuntimeError, error)
      end
    end
  end
end
