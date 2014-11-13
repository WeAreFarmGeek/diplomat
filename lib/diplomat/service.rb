require 'base64'
require 'faraday'

module Diplomat
  class Service < Diplomat::RestClient

    # Get a service by it's key
    # @param key [String] the key
    # @param scope [Symbol] :first or :all results
    # @return [OpenStruct] all data associated with the service
    def get key, scope=:first
      ret = @conn.get "/v1/catalog/service/#{key}"

      if scope == :all
        return JSON.parse(ret.body).map { |service| OpenStruct.new service }
      end
      return OpenStruct.new JSON.parse(ret.body).first
    end

    # @note This is sugar, see (#get)
    def self.get *args
      Diplomat::Service.new.get *args
    end

  end
end
