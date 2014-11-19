require 'faraday'
require 'json'

module Diplomat
  class RestClient

    def initialize api_connection=nil
      start_connection api_connection
    end

    private

    # Build the API Client
    # @param api_connection [Faraday::Connection,nil] supply mock API Connection
    def start_connection api_connection=nil
      @conn = api_connection ||= Faraday.new(:url => Diplomat.configuration.url) do |faraday|
        faraday.request  :url_encoded
        Diplomat.configuration.middleware.each do |middleware|
          faraday.use middleware
        end
        faraday.adapter  Faraday.default_adapter
        faraday.use      Faraday::Response::RaiseError
      end
    end

  end
end
