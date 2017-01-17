module Diplomat
  # Helper methods for interacting with the Consul RESTful API
  module ApiOptions
    def check_acl_token
      use_named_parameter('token', Diplomat.configuration.acl_token)
    end

    def use_cas(options)
      options ? use_named_parameter('cas', options[:cas]) : []
    end

    def use_consistency(options)
      options && options[:consistency] ? [options[:consistency].to_s] : []
    end
  end
end
