require 'faraday'

module Diplomat
  class RestClient

    def initialize api_client=nil
      start_connection api_client
    end

    private

    def start_connection api_client=nil
      @conn = api_client ||= Faraday.new(:url => Diplomat::url) do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
        faraday.use      Faraday::Response::RaiseError
      end
    end

  end
end
