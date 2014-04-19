require 'base64'
require 'faraday'

module Diplomat
  class Service < Diplomat::RestClient

    # Get a service by it's key
    # @param key [String] the key
    # @return [OpenStruct] all data associated with the service
    def get key
      ret = @conn.get "/v1/catalog/service/#{key}"
      return OpenStruct.new JSON.parse(ret.body).first
    end

    # @note This is sugar, see (#get)
    def self.get *args
      Diplomat::Service.new.get *args
    end

  end
end
