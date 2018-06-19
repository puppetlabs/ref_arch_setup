require "spec_helper"
require "fileutils"
require_relative "../../modules/ref_arch_setup/tasks/download_pe_tarball.rb"

TEST_VALID_URL = "https://test.com/test.tar.gz".freeze
TEST_VALID_BASENAME = "test.tar.gz".freeze
TEST_INVALID_URL = "httpz://test.com/test.tar.gx".freeze

TEST_DEST = "/tmp/ref_arch_setup".freeze
TEST_DEST_PATH = "/tmp/ref_arch_setup/test.tar.gz".freeze

describe "download_pe_tarball.rb" do

  describe "#init" do

    context "when the url and destination are specified" do

      it "sets the instance variables (and returns true?)" do
        skip "TODO: stub STDIN"
        # expect(init).to eq(true)
      end

    end

  end

  describe "#is_valid_url?" do

    context "when the url is valid" do

      it "returns true" do
        expect(is_valid_url?(TEST_VALID_URL)).to eq(true)
      end

    end

    context "when the url is not valid" do

      it "reports the error and returns false" do
        message = "Invalid URL: #{TEST_INVALID_URL}"
        expect(self).to receive(:puts).with(message)
        expect(is_valid_url?(TEST_INVALID_URL)).to eq(false)
      end

    end


  end

  describe "#is_valid_extension?" do

    context "when the extension is valid" do

      it "returns true" do
        expect(is_valid_extension?(TEST_VALID_URL)).to eq(true)
      end

    end

    context "when the extension is not valid" do

      it "reports the error and returns false" do
        extension = File.extname(TEST_INVALID_URL)
        message = "Invalid extension: #{extension} for URL: #{TEST_INVALID_URL}. Extension must be .gz"
        expect(self).to receive(:puts).with(message)
        expect(is_valid_extension?(TEST_INVALID_URL)).to eq(false)
      end

    end

  end

  describe "#ensure_destination" do

    context "when the specified directory exists" do

      it "returns true" do
        expect(File).to receive(:directory?).at_least(:once).and_return(true)
        expect(ensure_destination("/tmp/ref_arch_setup")).to eq(true)
      end

    end

    context "when the specified directory does not exist" do

      context "when the specified directory can be created" do

        it "reports, creates the directory, and returns true" do
          message = "Destination directory '#{TEST_DEST}' does not exist; attempting to create it"
          expect(self).to receive(:puts).with(message)

          expect(File).to receive(:directory?).once.and_return(false)
          expect(File).to receive(:directory?).twice.and_return(true)
          expect(FileUtils).to receive(:mkdir_p).and_return(true)
          expect(ensure_destination(TEST_DEST)).to eq(true)
         end

      end

      context "when the specified directory can not be created" do

        it "reports, attempts to create the directory, reports the error, and returns false" do
          message1 = "Destination directory '#{TEST_DEST}' does not exist; attempting to create it"
          message2 = "Destination #{TEST_DEST} could not be created"

          expect(self).to receive(:puts).with(message1)
          expect(self).to receive(:puts).with(message2)

          expect(File).to receive(:directory?).at_least(:once).and_return(false)
          expect(FileUtils).to receive(:mkdir_p).and_return(false)
          expect(ensure_destination(TEST_DEST)).to eq(false)
        end

      end

    end

  end

  describe "#download" do

    let(:TEST_DL) { Class.new }

    context "when the download is successful" do

      it "returns true" do
        message = "Downloading '#{TEST_VALID_URL}' to '#{TEST_DEST_PATH}'"
        allow(self).to receive(:puts)
        expect(self).to receive(:puts).with(message)

        expect(self).to receive(:open).with(TEST_VALID_URL).and_return(:TEST_DL)
        expect(IO).to receive(:copy_stream).with(:TEST_DL, TEST_DEST_PATH)

        expect(self).to receive(:verify_download).with(TEST_DEST_PATH).and_return(true)
        expect(download(TEST_VALID_URL, TEST_DEST_PATH)).to eq(true)
      end

    end

    context "when the download is not successful" do

      it "reports the error and returns false" do
        message = "Downloading '#{TEST_VALID_URL}' to '#{TEST_DEST_PATH}'"
        allow(self).to receive(:puts)
        expect(self).to receive(:puts).with(message)

        expect(self).to receive(:open).with(TEST_VALID_URL).and_return(:TEST_DL)
        expect(IO).to receive(:copy_stream).with(:TEST_DL, TEST_DEST_PATH)

        expect(self).to receive(:verify_download).with(TEST_DEST_PATH).and_return(false)
        expect(download(TEST_VALID_URL, TEST_DEST_PATH)).to eq(false)
      end

    end

  end

  # TODO: implement
  describe "#verify_download" do

    context "when verification is successful" do

      it "returns true" do
        skip "TODO: implement"
      end

    end

    context "when verification is not successful" do

      it "reports the error and returns false" do
        skip "TODO: implement"

      end

    end

  end

  describe "#is_valid_input?" do

    context "when the input is valid" do

      before {
        self.instance_variable_set(:@url, TEST_VALID_URL)
        self.instance_variable_set(:@destination, TEST_DEST)
      }

      it "returns true" do
        expect(self).to receive(:is_valid_url?).with(TEST_VALID_URL).and_return(true)
        expect(self).to receive(:is_valid_extension?).with(TEST_VALID_URL).and_return(true)

        expect(is_valid_input?).to eq(true)
      end

    end

    context "when the input is not valid" do

      # TODO: test each case

      before {
        self.instance_variable_set(:@url, TEST_INVALID_URL)
      }

      it "returns false" do
        expect(self).to receive(:is_valid_url?).with(TEST_INVALID_URL).and_return(false)
        expect(is_valid_input?).to eq(false)
      end

    end

  end

  describe "#execute_task" do

    before {
      self.instance_variable_set(:@url, TEST_VALID_URL)
      self.instance_variable_set(:@destination, TEST_DEST)
    }

    context "when the download is successful" do

      it "returns 0" do
        expect(File).to receive(:basename).with(TEST_VALID_URL).and_return(TEST_VALID_BASENAME)
        expect(self).to receive(:download).with(TEST_VALID_URL, TEST_DEST_PATH).and_return(true)
        expect(execute_task()).to eq(0)
      end

    end

    context "when the download is not successful" do

      it "reports the error and returns 1" do
        message = "Error downloading #{TEST_VALID_URL} to #{TEST_DEST_PATH}"
        allow(self).to receive(:puts)
        expect(self).to receive(:puts).with(message)
        expect(self).to receive(:download).with(TEST_VALID_URL, TEST_DEST_PATH).and_return(false)
        expect(execute_task()).to eq(1)
      end

    end

  end

end
