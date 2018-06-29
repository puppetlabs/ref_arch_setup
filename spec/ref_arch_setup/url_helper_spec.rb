require "spec_helper"
require_relative "../../lib/ref_arch_setup/url_helper.rb"

describe RefArchSetup::UrlHelper do

  let(:url_helper) { RefArchSetup::UrlHelper.new() }

  TEST_PE_DIR = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1".freeze
  TEST_PE_VER = "2018.1.0-rc14".freeze
  TEST_PLATFORM = "el-6-x86_64".freeze
  TEST_DIST = "puppet-enterprise-2018.1.0-rc14-el-6-x86_64".freeze
  TEST_VALID_URL = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1/puppet-enterprise-2018.1.0-rc14-el-6-x86_64.tar.gz"

  let!(:host) {{"pe_dir" => TEST_PE_DIR, "pe_ver" => TEST_PE_VER, "platform" => TEST_PLATFORM}}

  describe "#link_exists?" do

    context "when called as part of the example" do

      it "it returns true" do
        expect(url_helper.link_exists?(TEST_VALID_URL)).to eq(true)
      end

    end

  end

  describe "#prepare_ras_host" do

    context "when given a host with a pe_dir, pe_ver, and platform" do

      it "it sets and returns the filename as host['dist']" do
        expect(host["dist"]).to eq(nil)
        expect(url_helper.prepare_ras_host(host)).to eq(TEST_DIST)
        expect(host["dist"]).to eq(TEST_DIST)
      end

    end

  end

  describe "#get_ras_pe_tarball_url_with_prepare" do

    context "when given a host with a pe_dir, pe_ver, and platform" do

      context "when the link exists" do

        it "it returns the download URL" do
          expect(url_helper).to receive(:link_exists?).with(TEST_VALID_URL).and_return(true)
          expect(url_helper.get_ras_pe_tarball_url_with_prepare(host)).to eq(TEST_VALID_URL)
        end

      end

      context "when the link does not exist" do

        let!(:invalid_host) {{"pe_dir" => "xyz", "pe_ver" => TEST_PE_VER, "platform" => TEST_PLATFORM}}
        invalid_url = "xyz/#{TEST_DIST}.tar.gz"

        it "it raises an error" do
          expect(url_helper).to receive(:link_exists?).with(invalid_url).and_return(false)
          expect{url_helper.get_ras_pe_tarball_url_with_prepare(invalid_host)}.to raise_error(RuntimeError)
        end

      end


    end

  end

  describe "#get_ras_pe_tarball_url" do

    context "when given a host with a pe_dir, pe_ver, and platform" do

      context "when the link exists" do

        it "it returns the download URL" do
          expect(url_helper).to receive(:link_exists?).with(TEST_VALID_URL).and_return(true)
          expect(url_helper.get_ras_pe_tarball_url(host)).to eq(TEST_VALID_URL)
        end

      end

      context "when the link does not exist" do

        let!(:invalid_host) {{"pe_dir" => "xyz", "pe_ver" => TEST_PE_VER, "platform" => TEST_PLATFORM}}
        invalid_url = "xyz/#{TEST_DIST}.tar.gz"

        it "it raises an error" do
          expect(url_helper).to receive(:link_exists?).with(invalid_url).and_return(false)
          expect{url_helper.get_ras_pe_tarball_url(invalid_host)}.to raise_error(RuntimeError)
        end

      end

    end

    context "when given a host without a pe_dir" do

      let!(:invalid_host) {{"pe_ver" => TEST_PE_VER, "platform" => TEST_PLATFORM}}

      it "it raises an error" do
        expect(url_helper).not_to receive(:link_exists?)
        expect{url_helper.get_ras_pe_tarball_url(invalid_host)}.to raise_error(RuntimeError)
      end

    end

    context "when given a host without a pe_ver" do

      let!(:invalid_host) {{"pe_dir" => TEST_PE_DIR, "platform" => TEST_PLATFORM}}

      it "it raises an error" do
        expect(url_helper).not_to receive(:link_exists?)
        expect{url_helper.get_ras_pe_tarball_url(invalid_host)}.to raise_error(RuntimeError)
      end

    end

    context "when given a host without a platform" do

      let!(:invalid_host) {{"pe_dir" => TEST_PE_DIR, "pe_ver" => TEST_PE_VER}}

      it "it raises an error" do
        expect(url_helper).not_to receive(:link_exists?)
        expect{url_helper.get_ras_pe_tarball_url(invalid_host)}.to raise_error(RuntimeError)
      end

    end

  end

end
