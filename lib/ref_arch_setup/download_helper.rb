# rubocop:disable Metrics/ClassLength
require "oga"
require "net/http"

# General namespace for RAS
module RefArchSetup
  # Download helper methods
  class DownloadHelper
    # the 'Puppet Enterprise Version History' url
    PE_VERSIONS_URL = "https://puppet.com/misc/version-history".freeze

    # the base of the URL where prod PE tarballs are hosted
    BASE_PROD_URL = "https://s3.amazonaws.com/pe-builds/released".freeze

    # the minimum prod version supported by RAS
    MIN_PROD_VERSION = "2018.1.0".freeze

    # the supported platforms for PE installation using RAS
    PE_PLATFORMS = ["el-6-x86_64", "el-7-x86_64", "sles-12-x86_64", "ubuntu-16.04-amd64"].freeze

    def initialize
      @pe_versions_url = ENV["PE_VERSIONS_URL"] ? ENV["PE_VERSIONS_URL"] : PE_VERSIONS_URL
      @base_prod_url = ENV["BASE_PROD_URL"] ? ENV["BASE_PROD_URL"] : BASE_PROD_URL
      @min_prod_version = ENV["MIN_PROD_VERSION"] ? ENV["MIN_PROD_VERSION"] : MIN_PROD_VERSION
      @pe_platforms = PE_PLATFORMS
    end

    # Builds the prod tarball URL for the specified or default version of PE
    #
    # @author Bill Claytor
    #
    # @param [string] version The desired version of PE (default = "latest")
    # @param [string] host The target host for this PE tarball (default = "localhost")
    # @param [string] platform The target platform for this PE tarball
    #
    # *** Specifying the host will determine and validate the platform for the host
    # *** Specifying the platform will ignore the host value and only perform the validation
    #
    # @return [string] the prod tarball URL
    #
    # @example:
    # url = build_prod_tarball_url()
    # url = build_prod_tarball_url("2018.1.4", "master.mydomain.net", "")
    # url = build_prod_tarball_url("2018.1.4", "value_is_ignored", "sles-12-x86_64")
    #
    def self.build_prod_tarball_url(version = "latest", host = "localhost", platform = "default")
      pe_version = handle_prod_version(version)
      pe_platform = handle_platform(host, platform)
      url = "#{@base_prod_url}/#{pe_version}/puppet-enterprise-#{pe_version}-#{pe_platform}.tar.gz"
      puts "URL: #{url}"
      return url
    end

    # Retrieves the latest production PE version or verifies a user-specified version
    #
    # @author Bill Claytor
    #
    # @param [string] version The desired version of PE
    #
    # @return [string] The corresponding PE version
    #
    # @example:
    #   version = handle_prod_version("latest")
    #   version = handle_prod_version("2018.1.4")
    #
    def self.handle_prod_version(version)
      if version == "latest"
        pe_version = latest_prod_version
        puts "The latest version is: #{pe_version}"
      else
        success = ensure_valid_prod_version(version) && ensure_supported_prod_version(version)
        raise "Invalid version: #{version}" unless success

        pe_version = version
        puts "Proceeding with specified version: #{pe_version}"
      end

      return pe_version
    end

    # Retrieves the latest production version of PE from the 'Puppet Enterprise Version History'
    #
    # @author Bill Claytor
    #
    # @return [string] The latest production version of PE
    #
    # @example:
    #   latest_version = latest_prod_version
    #
    def self.latest_prod_version
      result = parse_prod_versions_url("//table/tbody/tr[1]/td[1]")
      latest_version = result.text
      return latest_version
    end

    # Determines whether the specified version is an actual production version of PE
    #
    # @author Bill Claytor
    #
    # @param [string] version The specified version of PE
    #
    # @return [true, false] Whether the specified version was found
    #
    # @example:
    #   result = ensure_valid_prod_version("2018.1.4")
    #
    def self.ensure_valid_prod_version(version)
      puts "Verifying specified PE version: #{version}"

      result = parse_prod_versions_url("//table/tbody/tr/td[contains(., '#{version}')]")
      found = result.text == version ? true : false

      puts "Specified version #{version} was found" if found
      raise "Specified version not found: #{version}" unless found

      return found
    end

    # Determines whether the specified version is supported by RAS
    #
    # @author Bill Claytor
    #
    # @param [string] version The specified version of PE
    #
    # @return [true, false] Whether the specified version is supported
    #
    # @example:
    #   result = ensure_supported_prod_version("2018.1.4")
    #
    def self.ensure_supported_prod_version(version)
      major_version = version.split(".")[0]
      supported_version = MIN_PROD_VERSION.split(".")[0]

      supported = major_version >= supported_version ? true : false
      puts "Specified version #{version} is supported by RAS" if supported
      puts "The minimum supported version is #{MIN_PROD_VERSION}" unless supported

      raise "Specified version #{version} is not supported by RAS" unless supported

      return supported
    end

    # Fetches the list of production PE versions from the 'Puppet Enterprise Version History'
    # *note: this is no longer used but has been left as an example
    # @author Bill Claytor
    #
    # @return [Oga::XML::NodeSet] The versions list
    #
    # @example:
    #   versions = fetch_prod_versions
    #
    def self.fetch_prod_versions
      versions = parse_prod_versions_url
      puts "Versions:"

      versions.each do |version|
        version_text = version.text
        puts version_text
      end
      puts

      return versions
    end

    # Parses the 'Puppet Enterprise Version History'
    # using the specified xpath and returns the result
    #
    # @author Bill Claytor
    #
    # @param [string] xpath The xpath to use when parsing the version history
    #
    # @return [Oga::XML::NodeSet] The resulting Oga NodeSet
    #
    # @example:
    #   versions = parse_prod_versions_url
    #   latest_version = parse_prod_versions_url("//table/tbody/tr[1]/td[1]")
    #   result = parse_prod_versions_url("//table/tbody/tr/td[contains(., '#{version}')]")
    #
    def self.parse_prod_versions_url(xpath = "//table/tbody/tr/td[1]")
      puts "Checking Puppet Enterprise Version History: #{@pe_versions_url}"

      uri = URI.parse(@pe_versions_url)
      response = Net::HTTP.get_response(uri)
      validate_response(response)

      document = Oga.parse_html(response.body)
      result = document.xpath(xpath)
      return result
    end

    # Determines whether the response is valid
    #
    # @author Bill Claytor
    #
    # @param [Net::HTTPResponse] res The HTTP response to evaluate
    # @param [Array] valid_response_codes The list of valid response codes
    # @param [Array] invalid_response_bodies The list of invalid response bodies
    #
    # @return [true,false] Based on whether the response is valid
    #
    # @example
    #   valid = validate_response(res)
    #   valid = validate_response(res, ["200", "123"], ["", nil])
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def self.validate_response(res, valid_response_codes = ["200"],
                               invalid_response_bodies = ["", nil])
      is_valid_response = false

      if res.nil?
        puts "Invalid response:"
        puts "nil"
        puts
      elsif !valid_response_codes.include?(res.code) ||
            invalid_response_bodies.include?(res.body)
        code = res.code.nil? ? "nil" : res.code
        body = res.body.nil? ? "nil" : res.body

        puts "Invalid response:"
        puts "code: #{code}"
        puts "body: #{body}"
        puts
      else
        is_valid_response = true
      end

      raise "Invalid response" unless is_valid_response

      return is_valid_response
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    # Handles the host and platform and determines the appropriate PE platform
    #
    # @author Bill Claytor
    #
    # @param [string] host The target host for this PE tarball (default = "localhost")
    # @param [string] platform The target platform for this PE tarball
    #
    # *** Specifying the host will determine and validate the platform for the host
    # *** Specifying the platform will ignore the host value and only perform the validation
    #
    # @return [string] The PE platform
    #
    # @example:
    #   handle_platform("my_host", "default")
    #   handle_platform("value_is_ignored", "sles-12-x86_64")
    #
    def self.handle_platform(host, platform)
      if platform == "default"
        puts "Default platform specified; determining platform for host"
        pe_platform = get_host_platform(host)
      else
        puts "Specified platform: #{platform}"
        pe_platform = platform
      end
      raise "Invalid PE platform: #{pe_platform}" unless valid_platform?(pe_platform)
      return pe_platform
    end

    # Handles the platform for the specified host using the host's facts
    #
    # @author Bill Claytor
    #
    # @param [string] host The target host
    #
    # @return [string] The corresponding platform for the specified host
    #
    # @example:
    #   platform = get_host_platform("localhost")
    #
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def self.get_host_platform(host)
      facts = retrieve_facts(host)
      os = facts[0]["result"]["os"]
      os_name = os["name"]
      os_family = os["family"]
      platform_type = nil

      case os_family
      when "RedHat"
        platform_type = "el"
        platform_arch = "x86_64"
        release = os["release"]["major"]
      when "SLES"
        platform_type = "sles"
        platform_arch = "x86_64"
        release = os["release"]["major"]
      when "Debian"
        if os_name == "Ubuntu"
          platform_type = "ubuntu"
          platform_arch = "amd64"
          release = os["release"]["full"]
        end
      end

      raise "Unable to determine platform for host: #{host}" unless platform_type
      platform = "#{platform_type}-#{release}-#{platform_arch}"
      puts "Host platform: #{platform}"

      return platform
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    # Retrieves the facts for the specified host(s) using the facts::retrieve plan
    #
    # @author Bill Claytor
    #
    # @param [string] hosts The host(s) from which to retrieve facts
    #
    # @return [string] The retrieved facts
    #
    # @example:
    #   facts = retrieve_facts("localhost")
    #
    def self.retrieve_facts(hosts)
      plan = "facts::retrieve"
      puts "Retrieving facts for hosts: #{hosts}"

      output = BoltHelper.run_forge_plan_with_bolt(plan, nil, hosts)

      begin
        facts = JSON.parse(output)
      rescue
        puts "Unable to parse bolt output"
        raise
      end

      return facts
    end

    # Determines whether the specified platform is a valid PE platform
    #
    # @author Bill Claytor
    #
    # @param [string] platform The platform
    #
    # @return [true,false] Based on validity of the specified platform
    #
    # @example:
    #   is_valid = valid_platform?("sles-12-x86_64")
    #
    # TODO: validate for a specified version?
    #
    def self.valid_platform?(platform)
      valid = @pe_platforms.include?(platform) ? true : false
      puts "Platform #{platform} is valid" if valid
      puts "Platform #{platform} is not valid" unless valid
      puts "Valid platforms are: #{@pe_platforms}" unless valid
      return valid
    end
  end
end
