require "spec_helper"
require_relative "../../lib/ref_arch_setup/url_helper.rb"

describe RefArchSetup::UrlHelper do

  let(:url_helper) { RefArchSetup::UrlHelper.new() }

  TEST_PE_DIR = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1".freeze
  TEST_PE_VER = "2018.1.0-rc14".freeze
  TEST_PLATFORM = "el-6-x86_64".freeze
  TEST_DIST = "puppet-enterprise-2018.1.0-rc14-el-6-x86_64".freeze
  TEST_EXPECTED_URL = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1/puppet-enterprise-2018.1.0-rc14-el-6-x86_64.tar.gz"

  let!(:host) {{"pe_dir" => TEST_PE_DIR, "pe_ver" => TEST_PE_VER, "platform" => TEST_PLATFORM}}

  describe "#prepare_ras_host" do

    context "when given a host with a pe_dir, pe_ver, and platform" do

      it "it sets and returns the filename as host['dist']" do
        expect(host["dist"]).to eq(nil)
        expect(url_helper.prepare_ras_host(host)).to eq(TEST_DIST)
        expect(host["dist"]).to eq(TEST_DIST)
      end

    end

  end

  describe "#get_ras_pe_tarball_url" do

    context "when given a host with a pe_dir, pe_ver, and platform" do

      it "it returns the download URL" do
        expect(url_helper.get_ras_pe_tarball_url(host)).to eq(TEST_EXPECTED_URL)
      end

    end

  end

  describe "#get_ras_pe_tarball_url_simple" do

    context "when given a host with a pe_dir, pe_ver, and platform" do

      it "it returns the download URL" do
        expect(url_helper.get_ras_pe_tarball_url_simple(host)).to eq(TEST_EXPECTED_URL)
      end

    end

  end

end
