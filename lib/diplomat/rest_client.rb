require 'faraday'
require 'json'

module Diplomat
  class RestClient

    def initialize api_connection=nil
      start_connection api_connection
    end

    def concat_url parts
        if parts.length > 1 then
            parts.first << '?' << parts.drop(1).join('&')
        else
            parts.first
        end
    end

    private

    # Build the API Client
    # @param api_connection [Faraday::Connection,nil] supply mock API Connection
    def start_connection api_connection=nil
      @conn = api_connection || Faraday.new(:url => Diplomat.configuration.url) do |faraday|
        faraday.adapter  Faraday.default_adapter
        faraday.request  :url_encoded
        faraday.response :raise_error

        Diplomat.configuration.middleware.each do |middleware|
          faraday.use middleware
        end
      end

      @conn_no_err = api_connection || Faraday.new(:url => Diplomat.configuration.url) do |faraday|
        faraday.adapter  Faraday.default_adapter
        faraday.request  :url_encoded

        Diplomat.configuration.middleware.each do |middleware|
          faraday.use middleware
        end
      end
    end

  end
end
