# General namespace for RAS
module RefArchSetup

  class UrlHelper

    def get_url(pe_dir, pe_ver, host)
      "#{pe_dir}/puppet-enterprise-#{pe_ver}-#{host}.tar.gz"
    end

  end

end