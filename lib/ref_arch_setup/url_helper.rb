# General namespace for RAS
module RefArchSetup
  # Code to illustrate a Beaker-based method of deriving a tarball URL
  class UrlHelper
    # Extracted from pe_utils.prepare_hosts
    #   this version leaves filename = "#{host['dist']}" to show how it was originally used
    def prepare_ras_host(host)
      # host['dist'] is used for the filename
      host["dist"] = "puppet-enterprise-#{host['pe_ver']}-#{host['platform']}"
    end

    # Extracted from pe_utils.fetch_pe_on_unix
    #   this assumes being called by beaker with a host (master)
    def get_ras_pe_url(host)
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
  end
end
