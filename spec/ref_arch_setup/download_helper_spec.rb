require "spec_helper"
require "json"

describe RefArchSetup::DownloadHelper do
  subject = RefArchSetup::DownloadHelper

  let(:test_versions_result) { Class.new }
  let(:test_pe_versions_uri) { Class.new }

  TEST_PE_VERSIONS_URL = "http://testing.net/pe-versions".freeze
  TEST_BASE_PROD_URL = "http://testing.net/pe-tarballs".freeze
  TEST_LATEST_VERSION = "2077.1.4".freeze
  TEST_OLDER_VERSION = "2076.3.10".freeze
  TEST_EL6_PLATFORM = "el-66-x86_64".freeze
  TEST_EL7_PLATFORM = "el-77-x86_64".freeze
  TEST_SLES_PLATFORM = "sles-111-x86_64".freeze
  TEST_UBUNTU_PLATFORM = "ubuntu-99.04-amd64".freeze
  TEST_INVALID_PLATFORM = "ubuntu-333.04-amd64".freeze
  TEST_PE_PLATFORMS = [TEST_EL6_PLATFORM,
                       TEST_EL7_PLATFORM,
                       TEST_SLES_PLATFORM,
                       TEST_UBUNTU_PLATFORM].freeze
  TEST_MIN_PROD_VERSION = "2076.1.0".freeze

  TEST_VALID_RESPONSE_BODY = "OK".freeze
  TEST_INVALID_RESPONSE_BODY = "".freeze
  TEST_VALID_RESPONSE_CODE = "200".freeze
  TEST_INVALID_RESPONSE_CODE = "777".freeze

  TEST_CENTOS_OUTPUT = '[
  {
    "node": "my_host",
    "status": "success",
    "result": {
      "os": {
        "name": "CentOS",
        "release": {
          "full": "77.2",
          "major": "77",
          "minor": "2"
        },
        "family": "RedHat"
      }
    }
  }
]'.freeze

  TEST_SLES_OUTPUT = '[
  {
    "node": "my_host",
    "status": "success",
    "result": {
      "os": {
        "name": "SLES",
        "release": {
          "full": "111.1",
          "major": "111",
          "minor": "2"
        },
        "family": "SLES"
      }
    }
  }
]'.freeze

  TEST_UBUNTU_OUTPUT = '[
  {
    "node": "my_host",
    "status": "success",
    "result": {
      "os": {
        "name": "Ubuntu",
        "release": {
          "full": "99.04",
          "major": "99",
          "minor": "2"
        },
        "family": "Debian"
      }
    }
  }
]'.freeze

  TEST_UNKNOWN_DEBIAN_OUTPUT = '[
  {
    "node": "my_host",
    "status": "success",
    "result": {
      "os": {
        "name": "SparkyLinux",
        "release": {
          "full": "1.1",
          "major": "777",
          "minor": "2"
        },
        "family": "Debian"
      }
    }
  }
]'.freeze

  TEST_UNKNOWN_OUTPUT = '[
  {
    "node": "my_host",
    "status": "success",
    "result": {
      "os": {
        "name": "Gentoo",
        "release": {
          "full": "1.1",
          "major": "111",
          "minor": "2"
        },
        "family": "Gentoo"
      }
    }
  }
]'.freeze

  TEST_CENTOS_FACTS = JSON.parse(TEST_CENTOS_OUTPUT)
  TEST_SLES_FACTS = JSON.parse(TEST_SLES_OUTPUT)
  TEST_UBUNTU_FACTS = JSON.parse(TEST_UBUNTU_OUTPUT)
  TEST_UNKNOWN_DEBIAN_FACTS = JSON.parse(TEST_UNKNOWN_DEBIAN_OUTPUT)
  TEST_UNKNOWN_FACTS = JSON.parse(TEST_UNKNOWN_OUTPUT)

  before do
    subject.instance_variable_set(:@pe_versions_url, TEST_PE_VERSIONS_URL)
    subject.instance_variable_set(:@base_prod_url, TEST_BASE_PROD_URL)
    subject.instance_variable_set(:@pe_platforms, TEST_PE_PLATFORMS)
    subject.instance_variable_set(:@min_prod_version, TEST_MIN_PROD_VERSION)
  end

  describe "#initialize" do
    context "when environment variables are specified" do
      versions_url = "http://this.test.net.versions"
      base_url = "http://this.test.net.base"
      min_version = "444.44.44"

      it "sets the expected properties to the specified values" do
        ENV["PE_VERSIONS_URL"] = versions_url
        ENV["BASE_PROD_URL"] = base_url
        ENV["MIN_PROD_VERSION"] = min_version
        test_subject = RefArchSetup::DownloadHelper.new

        expect(test_subject.instance_variable_get(:@pe_versions_url)).to eq(versions_url)
        expect(test_subject.instance_variable_get(:@base_prod_url)).to eq(base_url)
        expect(test_subject.instance_variable_get(:@min_prod_version)).to eq(min_version)
        expect(test_subject.instance_variable_get(:@pe_platforms)).to eq(subject::PE_PLATFORMS)
      end
    end

    context "when environment variables are not specified" do
      it "sets the properties to the default values" do
        ENV["PE_VERSIONS_URL"] = nil
        ENV["BASE_PROD_URL"] = nil
        ENV["MIN_PROD_VERSION"] = nil
        test_subject = RefArchSetup::DownloadHelper.new

        expect(test_subject.instance_variable_get(:@pe_versions_url))
          .to eq(subject::PE_VERSIONS_URL)
        expect(test_subject.instance_variable_get(:@base_prod_url)).to eq(subject::BASE_PROD_URL)
        expect(test_subject.instance_variable_get(:@min_prod_version))
          .to eq(subject::MIN_PROD_VERSION)
        expect(test_subject.instance_variable_get(:@pe_platforms)).to eq(subject::PE_PLATFORMS)
      end
    end
  end

  describe "#build_prod_tarball_url" do
    context "when no arguments are specified" do
      version = TEST_LATEST_VERSION
      host = "localhost"
      platform = "default"
      pe_platform = TEST_EL7_PLATFORM
      url = "#{TEST_BASE_PROD_URL}/#{version}/puppet-enterprise-#{version}-#{pe_platform}.tar.gz"

      it "uses the default values" do
        expect(subject).to receive(:handle_prod_version).with("latest").and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        subject.build_prod_tarball_url
      end

      it "outputs the expected URL" do
        expect(subject).to receive(:handle_prod_version).with("latest").and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        expect(subject).to receive(:puts).with("URL: #{url}")
        subject.build_prod_tarball_url
      end

      it "returns the expected URL" do
        expect(subject).to receive(:handle_prod_version).with("latest").and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        expect(subject.build_prod_tarball_url).to eq(url)
      end
    end

    context "when a version is specified" do
      version = TEST_OLDER_VERSION
      host = "localhost"
      platform = "default"
      pe_platform = TEST_EL7_PLATFORM
      url = "#{TEST_BASE_PROD_URL}/#{version}/puppet-enterprise-#{version}-#{pe_platform}.tar.gz"

      it "uses the specified version" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform)
        allow(subject).to receive(:puts)
        subject.build_prod_tarball_url(version)
      end

      it "gets the platform for localhost" do
        expect(subject).to receive(:handle_prod_version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        subject.build_prod_tarball_url(version)
      end

      it "outputs the expected URL" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        expect(subject).to receive(:puts).with("URL: #{url}")
        subject.build_prod_tarball_url(version)
      end

      it "returns the expected URL" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        expect(subject.build_prod_tarball_url(version)).to eq(url)
      end
    end

    context "when a version and host are specified" do
      version = TEST_OLDER_VERSION
      host = "my_host"
      platform = "default"
      pe_platform = TEST_EL7_PLATFORM
      url = "#{TEST_BASE_PROD_URL}/#{version}/puppet-enterprise-#{version}-#{pe_platform}.tar.gz"

      it "uses the specified version" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform)
        allow(subject).to receive(:puts)
        subject.build_prod_tarball_url(version, host)
      end

      it "gets the platform for the specified host" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        subject.build_prod_tarball_url(version, host)
      end

      it "outputs the expected URL" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        expect(subject).to receive(:puts).with("URL: #{url}")
        subject.build_prod_tarball_url(version, host)
      end

      it "returns the expected URL" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        expect(subject.build_prod_tarball_url(version, host)).to eq(url)
      end
    end

    context "when all arguments are specified" do
      version = TEST_OLDER_VERSION
      host = "my_host"
      platform = TEST_PE_PLATFORMS[3]
      pe_platform = platform
      url = "#{TEST_BASE_PROD_URL}/#{version}/puppet-enterprise-#{version}-#{pe_platform}.tar.gz"

      it "uses the specified version and platform" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        subject.build_prod_tarball_url(version, host, platform)
      end

      it "outputs the expected URL" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        expect(subject).to receive(:puts).with("URL: #{url}")
        subject.build_prod_tarball_url(version, host, platform)
      end

      it "returns the expected URL" do
        expect(subject).to receive(:handle_prod_version).with(version).and_return(version)
        expect(subject).to receive(:handle_platform).with(host, platform).and_return(pe_platform)
        allow(subject).to receive(:puts)
        expect(subject.build_prod_tarball_url(version, host, platform)).to eq(url)
      end
    end
  end

  describe "#handle_prod_version" do
    context "when the specified version is 'latest'" do
      it "gets the latest prod version" do
        version = "latest"
        pe_version = TEST_LATEST_VERSION

        expect(subject).to receive(:latest_prod_version).and_return(pe_version)
        expect(subject).to receive(:puts).with("The latest version is: #{pe_version}")
        expect(subject.handle_prod_version(version)).to eq(pe_version)
      end
    end

    context "when the specified version is a valid version" do
      it "returns the specified version" do
        version = TEST_LATEST_VERSION
        pe_version = TEST_LATEST_VERSION
        message = "Proceeding with specified version: #{version}"

        expect(subject).not_to receive(:latest_prod_version)
        expect(subject).to receive(:ensure_valid_prod_version).with(version).and_return(true)
        expect(subject).to receive(:ensure_supported_prod_version).with(version).and_return(true)
        expect(subject).to receive(:puts).with(message)
        expect(subject.handle_prod_version(version)).to eq(pe_version)
      end
    end

    context "when the specified version is not a valid version" do
      it "raises an error" do
        version = "1.2.3"
        error = "Invalid version: #{version}"

        expect(subject).not_to receive(:latest_prod_version)
        expect(subject).to receive(:ensure_valid_prod_version).with(version).and_return(false)
        expect(subject).not_to receive(:puts).with("Using specified version: #{version}")
        expect { subject.handle_prod_version(version) }.to raise_error(RuntimeError, error)
      end
    end
  end

  describe "#latest_prod_version" do
    context "when called" do
      it "returns the first version from the prod versions list" do
        expect(subject).to receive(:parse_prod_versions_url).and_return(test_versions_result)
        expect(test_versions_result).to receive(:text).and_return(TEST_LATEST_VERSION)
        expect(subject.latest_prod_version).to eq(TEST_LATEST_VERSION)
      end
    end
  end

  describe "#ensure_valid_prod_version" do
    context "when the specified version is found" do
      version = TEST_LATEST_VERSION
      message = "Verifying specified PE version: #{version}"

      it "outputs helpful messages" do
        result = "Specified version #{version} was found"

        expect(subject).to receive(:parse_prod_versions_url).and_return(test_versions_result)
        expect(subject).to receive(:puts).with(message)
        expect(subject).to receive(:puts).with(result)

        expect(test_versions_result).to receive(:text).and_return(version)
        subject.ensure_valid_prod_version(version)
      end

      it "returns true" do
        expect(subject).to receive(:parse_prod_versions_url).and_return(test_versions_result)
        expect(test_versions_result).to receive(:text).and_return(version)
        allow(subject).to receive(:puts)
        expect(subject.ensure_valid_prod_version(version)).to eq(true)
      end
    end

    context "when the specified version is not found" do
      version = "x.y.z"
      message = "Verifying specified PE version: #{version}"

      it "outputs only the expected messages (and raises an error)" do
        result = "Specified version #{version} was not found"

        expect(subject).to receive(:parse_prod_versions_url).and_return(test_versions_result)
        expect(subject).to receive(:puts).with(message)
        expect(subject).not_to receive(:puts).with(result)

        expect(test_versions_result).to receive(:text).and_return("")
        expect { subject.ensure_valid_prod_version(version) }.to raise_error(RuntimeError)
      end

      it "raises the expected error" do
        error = "Specified version not found: #{version}"
        allow(subject).to receive(:puts)
        expect(subject).to receive(:parse_prod_versions_url).and_return(test_versions_result)
        expect(test_versions_result).to receive(:text).and_return("")
        expect { subject.ensure_valid_prod_version(version) }.to raise_error(RuntimeError, error)
      end
    end
  end

  describe "#ensure_supported_prod_version" do
    context "when the version is supported" do
      version = "2018.1.4"
      message = "Specified version #{version} is supported by RAS"

      it "outputs a confirmation" do
        expect(subject).to receive(:puts).with(message)
        subject.ensure_supported_prod_version(version)
      end

      it "returns true" do
        allow(subject).to receive(:puts)
        expect(subject.ensure_supported_prod_version(version)).to eq(true)
      end
    end

    context "when the version is not supported" do
      version = "2017.1.4"
      message = "The minimum supported version is #{subject::MIN_PROD_VERSION}"
      error = "Specified version #{version} is not supported by RAS"

      it "outputs an explanation (and raises an error)" do
        expect(subject).to receive(:puts).with(message)
        expect { subject.ensure_supported_prod_version(version) }
          .to raise_error(RuntimeError)
      end

      it "raises the expected error" do
        allow(subject).to receive(:puts)
        expect { subject.ensure_supported_prod_version(version) }
          .to raise_error(RuntimeError, error)
      end
    end
  end

  describe "#fetch_prod_versions" do
    context "when called" do
      it "returns the default result from parse_prod_versions_url" do
        allow(subject).to receive(:puts)
        expect(subject).to receive(:parse_prod_versions_url).and_return(test_versions_result)
        expect(test_versions_result).to receive(:each)
        expect(subject.fetch_prod_versions).to eq(test_versions_result)
      end
    end
  end

  describe "#parse_prod_versions_url" do
    let(:test_net_http) { Class.new }
    let(:test_uri) { Class.new }
    let(:test_oga) { Class.new }

    let(:test_http_response) { Class.new }
    let(:test_body) { Class.new }
    let(:test_document) { Class.new }
    let(:test_result) { Class.new }

    message = "Checking Puppet Enterprise Version History: #{TEST_PE_VERSIONS_URL}"

    before do
      stub_const("Net::HTTP", test_net_http)
      stub_const("URI", test_uri)
      stub_const("Oga", test_oga)
    end

    context "when the response is valid" do
      context "when an xpath is specified" do
        it "uses the specified xpath and returns the result" do
          xpath = "//table/tbody/tr[1]/td[1]"

          expect(subject).to receive(:puts).with(message)

          expect(test_uri).to receive(:parse)
            .with(TEST_PE_VERSIONS_URL).and_return(test_pe_versions_uri)

          expect(test_net_http).to receive(:get_response)
            .with(test_pe_versions_uri).and_return(test_http_response)

          expect(subject).to receive(:validate_response)
            .with(test_http_response).and_return(true)

          expect(test_http_response).to receive(:body).and_return(test_body)

          expect(test_oga).to receive(:parse_html)
            .with(test_body).and_return(test_document)

          expect(test_document).to receive(:xpath)
            .with(xpath).and_return(test_result)

          expect(subject.parse_prod_versions_url(xpath)).to eq(test_result)
        end
      end

      context "when an xpath is not specified" do
        it "uses the default xpath and returns the versions" do
          xpath = "//table/tbody/tr/td[1]"

          expect(subject).to receive(:puts).with(message)

          expect(test_uri).to receive(:parse)
            .with(TEST_PE_VERSIONS_URL).and_return(test_pe_versions_uri)

          expect(test_net_http).to receive(:get_response)
            .with(test_pe_versions_uri).and_return(test_http_response)

          expect(subject).to receive(:validate_response)
            .with(test_http_response).and_return(true)

          expect(test_http_response).to receive(:body).and_return(test_body)

          expect(test_oga).to receive(:parse_html)
            .with(test_body).and_return(test_document)

          expect(test_document).to receive(:xpath)
            .with(xpath).and_return(test_result)

          expect(subject.parse_prod_versions_url).to eq(test_result)
        end
      end
    end

    context "when the response is not valid" do
      it "raises an error" do
        expect(subject).to receive(:puts).with(message)

        expect(test_uri).to receive(:parse)
          .with(TEST_PE_VERSIONS_URL).and_return(test_pe_versions_uri)

        expect(test_net_http).to receive(:get_response)
          .with(test_pe_versions_uri).and_return(test_http_response)

        expect(subject).to receive(:validate_response)
          .with(test_http_response).and_raise(RuntimeError)

        expect(test_http_response).not_to receive(:body)
        expect(test_oga).not_to receive(:parse_html)

        expect { subject.parse_prod_versions_url }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#validate_response" do
    let(:test_http_response) { Class.new }

    context "when a valid response is provided" do
      code = TEST_VALID_RESPONSE_CODE
      body = TEST_VALID_RESPONSE_BODY

      it "returns true" do
        expect(test_http_response).to receive(:nil?).and_return(false)
        expect(test_http_response).to receive(:code).and_return(code)
        expect(test_http_response).to receive(:body).and_return(body)

        expect(subject.validate_response(test_http_response)).to eq(true)
      end
    end

    context "when an invalid response is provided" do
      message = "Invalid response:"
      error = "Invalid response"

      context "when the response is nil" do
        it "outputs the expected messages (and raises an error)" do
          expect(subject).to receive(:puts).with(message)
          expect(subject).to receive(:puts).with("nil")
          expect(subject).to receive(:puts).with(no_args)
          expect { subject.validate_response(nil) }.to raise_error(RuntimeError)
        end

        it "raises the expected error" do
          allow(subject).to receive(:puts)
          expect { subject.validate_response(nil) }.to raise_error(RuntimeError, error)
        end
      end

      context "when the response code is not valid" do
        code = TEST_INVALID_RESPONSE_CODE
        body = TEST_VALID_RESPONSE_BODY

        code_message = "code: #{code}"
        body_message = "body: #{body}"

        it "outputs the expected messages (and raises an error)" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          expect(subject).to receive(:puts).with(message)
          expect(subject).to receive(:puts).with(code_message)
          expect(subject).to receive(:puts).with(body_message)
          expect(subject).to receive(:puts).with(no_args)

          expect { subject.validate_response(test_http_response) }.to raise_error(RuntimeError)
        end

        it "raises the expected error" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          allow(subject).to receive(:puts)
          expect { subject.validate_response(test_http_response) }
            .to raise_error(RuntimeError, error)
        end
      end

      context "when the response code is nill" do
        code = nil
        body = TEST_VALID_RESPONSE_BODY

        code_message = "code: nil"
        body_message = "body: #{body}"

        it "outputs the expected messages (and raises an error)" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          expect(subject).to receive(:puts).with(message)
          expect(subject).to receive(:puts).with(code_message)
          expect(subject).to receive(:puts).with(body_message)
          expect(subject).to receive(:puts).with(no_args)

          expect { subject.validate_response(test_http_response) }.to raise_error(RuntimeError)
        end

        it "raises the expected error" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          allow(subject).to receive(:puts)
          expect { subject.validate_response(test_http_response) }
            .to raise_error(RuntimeError, error)
        end
      end

      context "when the response body is empty" do
        code = TEST_VALID_RESPONSE_CODE
        body = TEST_INVALID_RESPONSE_BODY
        code_message = "code: #{code}"
        body_message = "body: #{body}"

        it "outputs the expected messages (and raises an error)" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          expect(subject).to receive(:puts).with(message)
          expect(subject).to receive(:puts).with(code_message)
          expect(subject).to receive(:puts).with(body_message)
          expect(subject).to receive(:puts).with(no_args)

          expect { subject.validate_response(test_http_response) }.to raise_error(RuntimeError)
        end

        it "raises the expected error" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          allow(subject).to receive(:puts)

          expect { subject.validate_response(test_http_response) }
            .to raise_error(RuntimeError, error)
        end
      end

      context "when the response body is nil" do
        code = TEST_VALID_RESPONSE_CODE
        body = nil
        code_message = "code: #{code}"
        body_message = "body: nil"

        it "outputs the expected messages (and raises an error)" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          expect(subject).to receive(:puts).with(message)
          expect(subject).to receive(:puts).with(code_message)
          expect(subject).to receive(:puts).with(body_message)
          expect(subject).to receive(:puts).with(no_args)

          expect { subject.validate_response(test_http_response) }.to raise_error(RuntimeError)
        end

        it "raises the expected error" do
          expect(test_http_response).to receive(:nil?).at_least(:once).and_return(false)
          expect(test_http_response).to receive(:code).at_least(:once).and_return(code)
          expect(test_http_response).to receive(:body).at_least(:once).and_return(body)

          allow(subject).to receive(:puts)

          expect { subject.validate_response(test_http_response) }
            .to raise_error(RuntimeError, error)
        end
      end
    end
  end

  describe "#handle_platform" do
    context "when platform is 'default'" do
      context "when the host platform is valid" do
        host = "my_host"
        platform = "default"
        pe_platform = TEST_EL7_PLATFORM

        it "outputs the expected message" do
          expect(subject).to receive(:puts)
            .with("Default platform specified; determining platform for host")

          expect(subject).to receive(:get_host_platform)
            .with(host).and_return(pe_platform)

          expect(subject).not_to receive(:puts).with("Specified platform: #{pe_platform}")

          expect(subject).to receive(:valid_platform?)
            .with(pe_platform).and_return(true)

          subject.handle_platform(host, platform)
        end

        it "returns the validated platform for the specified host" do
          allow(subject).to receive(:puts)

          expect(subject).to receive(:get_host_platform)
            .with(host).and_return(pe_platform)

          expect(subject).to receive(:valid_platform?)
            .with(pe_platform).and_return(true)

          expect(subject.handle_platform(host, platform)).to eq(pe_platform)
        end
      end

      context "when the host platform is not valid" do
        host = "my_host"
        platform = "default"
        pe_platform = TEST_EL7_PLATFORM
        error = "Invalid PE platform: #{pe_platform}"
        it "outputs the expected message (and raises an error)" do
          expect(subject).to receive(:puts)
            .with("Default platform specified; determining platform for host")

          expect(subject).to receive(:get_host_platform)
            .with(host).and_return(pe_platform)

          expect(subject).not_to receive(:puts).with("Specified platform: #{pe_platform}")

          expect(subject).to receive(:valid_platform?)
            .with(pe_platform).and_return(false)

          expect { subject.handle_platform(host, platform) }
            .to raise_error(RuntimeError)
        end

        it "raises the expected error" do
          allow(subject).to receive(:puts)

          expect(subject).to receive(:get_host_platform)
            .with(host).and_return(pe_platform)

          expect(subject).to receive(:valid_platform?)
            .with(pe_platform).and_return(false)

          expect { subject.handle_platform(host, platform) }
            .to raise_error(RuntimeError, error)
        end
      end
    end

    context "when the platform is not 'default'" do
      context "when the platform is a valid PE platform" do
        host = "my_host"
        platform = TEST_SLES_PLATFORM
        pe_platform = platform

        it "successfully validates the specified platform" do
          expect(subject).not_to receive(:puts)
            .with("Default platform specified; determining platform for host")

          expect(subject).not_to receive(:get_host_platform).with(host)
          expect(subject).not_to receive(:puts).with("platform: #{pe_platform}")

          expect(subject).to receive(:puts).with("Specified platform: #{pe_platform}")
          expect(subject).to receive(:valid_platform?).with(pe_platform).and_return(true)

          expect(subject.handle_platform(host, platform)).to eq(pe_platform)
        end
      end

      context "when the platform is not a valid PE platform" do
        host = "my_host"
        platform = "invalid_platform"
        pe_platform = platform
        error = "Invalid PE platform: #{pe_platform}"

        it "outputs the expected message (and raises an error)" do
          expect(subject).not_to receive(:puts)
            .with("Default platform specified; determining platform for host")
          expect(subject).not_to receive(:get_host_platform).with(host)
          expect(subject).not_to receive(:puts).with("platform: #{pe_platform}")

          expect(subject).to receive(:puts).with("Specified platform: #{pe_platform}")

          expect(subject).to receive(:valid_platform?)
            .with(pe_platform).and_return(false)

          expect { subject.handle_platform(host, platform) }
            .to raise_error(RuntimeError)
        end

        it "raises the expected error" do
          allow(subject).to receive(:puts)
          expect(subject).to receive(:valid_platform?)
            .with(pe_platform).and_return(false)

          expect { subject.handle_platform(host, platform) }
            .to raise_error(RuntimeError, error)
        end
      end
    end
  end

  describe "#get_host_platform" do
    context "when the host os family is RedHat" do
      it "returns the correct platform string" do
        host = "my_host"
        pe_platform = TEST_EL7_PLATFORM
        message = "Host platform: #{pe_platform}"

        expect(subject).to receive(:retrieve_facts)
          .with(host).and_return(TEST_CENTOS_FACTS)
        expect(subject).to receive(:puts).with(message)
        expect(subject.get_host_platform(host)).to eq(pe_platform)
      end
    end

    context "when the host os family is SLES" do
      it "returns the correct platform string" do
        host = "my_host"
        pe_platform = TEST_SLES_PLATFORM
        message = "Host platform: #{pe_platform}"

        expect(subject).to receive(:retrieve_facts)
          .with(host).and_return(TEST_SLES_FACTS)
        expect(subject).to receive(:puts).with(message)
        expect(subject.get_host_platform(host)).to eq(pe_platform)
      end
    end

    context "when the host os family is Debian" do
      context "when the host os name is Ubuntu" do
        it "returns the correct platform string" do
          host = "my_host"
          pe_platform = TEST_UBUNTU_PLATFORM
          message = "Host platform: #{pe_platform}"

          expect(subject).to receive(:retrieve_facts)
            .with(host).and_return(TEST_UBUNTU_FACTS)
          expect(subject).to receive(:puts).with(message)
          expect(subject.get_host_platform(host)).to eq(pe_platform)
        end
      end

      context "when the host os name is not Ubuntu" do
        it "raises an error" do
          host = "my_host"
          error = "Unable to determine platform for host: #{host}"

          expect(subject).to receive(:retrieve_facts)
            .with(host).and_return(TEST_UNKNOWN_DEBIAN_FACTS)

          expect { subject.get_host_platform(host) }
            .to raise_error(RuntimeError, error)
        end
      end

      context "when the host os family is not recognized " do
        it "raises an error" do
          host = "my_host"
          error = "Unable to determine platform for host: #{host}"

          expect(subject).to receive(:retrieve_facts)
            .with(host).and_return(TEST_UNKNOWN_FACTS)

          expect { subject.get_host_platform(host) }
            .to raise_error(RuntimeError, error)
        end
      end
    end
  end

  # TODO: separate test cases
  describe "#retrieve_facts" do
    plan = "facts::retrieve"
    hosts = "my_host"
    message = "Retrieving facts for hosts: #{hosts}"

    context "when bolt successfully runs the facts plan" do
      output = TEST_CENTOS_OUTPUT
      facts = TEST_CENTOS_FACTS

      it "returns the facts" do
        expect(subject).to receive(:puts).with(message)
        expect(RefArchSetup::BoltHelper).to receive(:run_forge_plan_with_bolt)
          .with(plan, nil, hosts).and_return(output)
        expect(JSON).to receive(:parse)
          .with(output).and_return(facts)

        expect(subject.retrieve_facts(hosts)).to eq(facts)
      end
    end

    context "when bolt is not able to successfully run the facts plan" do
      context "when the output can't be parsed" do
        it "outputs a helpful message and re-raises the error" do
          invalid_output = "123"
          helpful_message = "Unable to parse bolt output"
          error_message = "JSON parse error"
          expect(subject).to receive(:puts).with(message)
          expect(RefArchSetup::BoltHelper).to receive(:run_forge_plan_with_bolt)
            .with(plan, nil, hosts).and_return(invalid_output)
          expect(JSON).to receive(:parse)
            .with(invalid_output).and_raise(RuntimeError, error_message)
          expect(subject).to receive(:puts).with(helpful_message)

          expect { subject.retrieve_facts(hosts) }
            .to raise_error(RuntimeError, error_message)
        end
      end
    end
  end

  describe "#valid_platform?" do
    context "when the platform is included in the list of valid platforms" do
      platform = TEST_UBUNTU_PLATFORM
      result = "Platform #{platform} is valid"

      it "outputs the expected messages" do
        expect(subject).to receive(:puts).with(result)

        subject.valid_platform?(platform)
      end

      it "returns true" do
        allow(subject).to receive(:puts)
        expect(subject.valid_platform?(platform)).to eq(true)
      end
    end

    context "when the platform is not included in the list of valid platforms" do
      platform = TEST_INVALID_PLATFORM
      result = "Platform #{platform} is not valid"
      platforms_message = "Valid platforms are: #{TEST_PE_PLATFORMS}"

      it "outputs the expected messages" do
        expect(subject).to receive(:puts).with(result)
        expect(subject).to receive(:puts).with(platforms_message)

        subject.valid_platform?(platform)
      end

      it "returns false" do
        allow(subject).to receive(:puts)
        expect(subject.valid_platform?(platform)).to eq(false)
      end
    end
  end
end
