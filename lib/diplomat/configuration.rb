module Diplomat
  class Configuration
    attr_accessor :middleware
    attr_accessor :url, :acl_token

    # Override defaults for configuration
    # @param url [String] consul's connection URL
    # @param acl_token [String] a connection token used when making requests to consul
    def initialize(url="http://localhost:8500", acl_token=nil)
      @middleware = []
      @url = url
      @acl_token = acl_token
    end

    # Define a middleware for Faraday
    # @param middleware [Class] Faraday Middleware class
    def middleware=(middleware)
      return @middleware = middleware if middleware.is_a? Array
      @middleware = [middleware]
    end

  end
end

