module Diplomat
  module ApiOptions
    def check_acl_token
      use_named_parameter("token", Diplomat.configuration.acl_token)
    end

    def use_cas(options)
      if options then use_named_parameter("cas", options[:cas]) else [] end
    end

    def use_consistency(options)
      if options && options[:consistency] then ["#{options[:consistency]}"] else [] end
    end
  end
end
