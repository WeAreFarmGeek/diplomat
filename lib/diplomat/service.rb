require 'base64'
require 'faraday'

module Diplomat
  class Service < Diplomat::RestClient

    def get key
      ret = @conn.get "/v1/service/#{@key}"
      return JSON.parse ret
    end

  end
end
