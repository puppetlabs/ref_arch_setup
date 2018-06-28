# General namespace for RAS
module RefArchSetup
  # Code to illustrate a Beaker-based method of deriving a tarball URL
  class UrlHelper
    # Determine is a given URL is accessible
    # *** copied from Beaker to illustrate the example ***
    #
    # @param [String] link The URL to examine
    # @return [Boolean] true if the URL has a '200' HTTP response code, false otherwise
    # @example
    #  extension = link_exists?("#{URL}.tar.gz") ? ".tar.gz" : ".tar"
    #
    def link_exists?(link)
      require "net/http"
      require "net/https"
      require "open-uri"
      url = URI.parse(link)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = (OpenSSL::SSL::VERIFY_NONE)
      http.start do |http|
        return http.head(url.request_uri).code == "200"
      end
    end

    # Prepares the host by setting the host["dist"]
    #
    # Extracted from pe_utils.prepare_hosts
    #   this version leaves filename = "#{host['dist']}" to show how it was originally used
    #
    # @param [Host] host The unix style host where PE will be installed
    # @return [String] the host["dist"] aka PE filename
    # @example
    #   prepare_ras_host(host)
    #
    def prepare_ras_host(host)
      # host['dist'] is used for the filename
      host["dist"] = "puppet-enterprise-#{host["pe_ver"]}-#{host["platform"]}"
    end

    # Extracted from pe_utils.fetch_pe_on_unix
    #   assumes being called by beaker with a host (master)
    #   this version calls prepare_ras_host which sets host["dist"];
    #   similar to beaker implementation
    #
    # @param [Host] host The unix style host where PE will be installed
    # @return [String] the tarball URL
    # @example
    #   url = get_ras_pe_tarball_url(host)
    #
    def get_ras_pe_tarball_url(host)
      prepare_ras_host(host)
      path = host["pe_dir"]
      filename = host["dist"]
      extension = ".tar.gz"
      url = "#{path}/#{filename}#{extension}"

      unless link_exists?(url)
        raise "attempting to construct download URL for #{host}, #{url} does not exist"
      end

      return url
    end

    # Extracted from pe_utils.fetch_pe_on_unix
    #   assumes being called by beaker with a host (master)
    #   this version is simplified by removing the call to prepare_ras_host
    #
    # @param [Host] host The unix style host where PE will be installed
    # @return [String] the tarball URL
    # @example
    #   url = get_ras_pe_tarball_url(host)
    #
    def get_ras_pe_tarball_url_simple(host)
      path = host["pe_dir"]
      filename = "puppet-enterprise-#{host["pe_ver"]}-#{host["platform"]}"
      extension = ".tar.gz"
      url = "#{path}/#{filename}#{extension}"

      unless link_exists?(url)
        raise "attempting to construct download URL for #{host}, #{url} does not exist"
      end

      return url
    end

  end
end
