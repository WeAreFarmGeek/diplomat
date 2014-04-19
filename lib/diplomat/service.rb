require 'base64'
require 'faraday'

module Diplomat
  class Service < Diplomat::RestClient

    def get key
      ret = @conn.get "/v1/catalog/service/#{key}"
      return JSON.parse ret.body
    end

    def self.get *args
      Diplomat::Service.new.get *args
    end

  end
end
