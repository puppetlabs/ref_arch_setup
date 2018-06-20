require "spec_helper"

describe RefArchSetup::UrlHelper do

  let(:url_helper) { RefArchSetup::UrlHelper.new() }

  TEST_PE_DIR = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1".freeze
  TEST_PE_VER = "2018.1.0-rc14".freeze
  TEST_HOST = "el-6-x86_64".freeze
  TEST_EXPECTED_URL = "http://enterprise.delivery.puppetlabs.net/archives/internal/2018.1/puppet-enterprise-2018.1.0-rc14-el-6-x86_64.tar.gz"

  describe "#get_url" do

    context "when given a pe_dir, pe_ver, and host" do

      it "it returns the download URL" do

        expect(url_helper.get_url(TEST_PE_DIR, TEST_PE_VER, TEST_HOST)).to eq(TEST_EXPECTED_URL)

      end

    end

  end

end
