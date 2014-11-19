module Diplomat
  class Configuration
    attr_accessor :middleware
    attr_accessor :url

    def initialize
      @middleware = []
      @url = "http://localhost:8500"
    end

    def middleware=(middleware)
      return @middleware = middleware if middleware.is_a? Array
      @middleware = [middleware]
    end

  end
end

