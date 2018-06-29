# General namespace for RAS
module RefArchSetup
  # Code to illustrate a Beaker-based method of deriving a tarball URL
  #
  # This will be implemented as an update to Beaker; it can either be
  # added with some duplication of existing code or as part of a refactor
  # to isolate the URL building functionality from the fetch and extraction
  # process.
  #
  class UrlHelper
    # Determine if a given URL is accessible
    # *** added as a stub for the version in Beaker WebHelpers ***
    #
    # @param [String] _link The URL to examine
    # @return [Boolean] true
    # @example
    #  link_exists?(url)
    #
    def link_exists?(_link)
      true
    end

    # Prepares the host by setting the host["dist"]
    #
    # Extracted from pe_utils.prepare_hosts to show how it is used there
    #
    # @param [Host] host The unix style host where PE will be installed
    # @return [String] the host["dist"] aka PE filename
    # @example
    #   prepare_ras_host(host)
    #
    def prepare_ras_host(host)
      # host['dist'] is used for the filename
      host["dist"] = "puppet-enterprise-#{host['pe_ver']}-#{host['platform']}"
    end

    # Builds a PE tarball URL for the specified host using prepare_ras_host
    #
    # The host must include a pe_dir, pe_ver, and platform
    #
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
    def get_ras_pe_tarball_url_with_prepare(host)
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

    # Builds a PE tarball URL for the specified host
    #
    # The host must include a pe_dir, pe_ver, and platform
    #
    # Extracted from pe_utils.fetch_pe_on_unix
    #   assumes being called by beaker with a host (master)
    #   this version is simplified by removing the call to prepare_ras_host
    #
    # @param [Host] host The unix style host where PE will be installed
    # @return [String] the tarball URL
    # @example
    #   url = get_ras_pe_tarball_url(host)
    #
    def get_ras_pe_tarball_url(host)
      raise "host must include a pe_dir value" unless host["pe_dir"]
      raise "host must include a pe_ver value" unless host["pe_ver"]
      raise "host must include a platform value" unless host["platform"]

      path = host["pe_dir"]
      version = host["pe_ver"]
      platform = host["platform"]
      filename = "puppet-enterprise-#{version}-#{platform}"
      extension = ".tar.gz"
      url = "#{path}/#{filename}#{extension}"

      unless link_exists?(url)
        raise "attempting to construct download URL for #{host}, #{url} does not exist"
      end

      return url
    end
  end
end
