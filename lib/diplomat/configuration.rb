module Diplomat
  class Configuration
    attr_accessor :middleware
    attr_accessor :url, :acl_token

    def initialize(url="http://localhost:8500", acl_token=nil)
      @middleware = []
      @url = url
      @acl_token = acl_token
    end

    def middleware=(middleware)
      return @middleware = middleware if middleware.is_a? Array
      @middleware = [middleware]
    end

  end
end

