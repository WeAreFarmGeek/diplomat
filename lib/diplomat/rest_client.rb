require 'faraday'
require 'json'

module Diplomat
  class RestClient

    def initialize api_connection=nil
      start_connection api_connection
    end

    def use_named_parameter(name, value)
      if value then ["#{name}=#{value}"] else [] end
    end

    def concat_url parts
      if parts.length > 1 then
        parts.first + '?' + parts.drop(1).join('&')
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

    # Parse the body, apply it to the raw attribute
    def parse_body
      @raw = JSON.parse(@raw.body)
    end

    # Get the value from the raw output
    def return_value
      if @raw.count == 1
        @value = @raw.first["Value"]
        @value = Base64.decode64(@value) unless @value.nil?
      else
        @value = @raw.map do |e|
          {
            :key => e["Key"],
            :value => (Base64.decode64(e["Value"]) unless e["Value"].nil?)
          }
        end
      end
    end

    # Get the name and payload(s) from the raw output
    def return_payload
      @value = @raw.map do |e|
        { :name => e["Name"],
          :payload => (Base64.decode64(e["Payload"]) unless e["Payload"].nil?) }
      end
    end

  end
end
