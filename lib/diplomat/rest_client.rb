require 'faraday'
require 'json'

module Diplomat
  class RestClient

    @access_methods = []

    # Initialize the fadaray connection
    # @param api_connection [Faraday::Connection,nil] supply mock API Connection
    def initialize api_connection=nil
      start_connection api_connection
    end

    # Format url parameters into strings correctly
    # @param name [String] the name of the parameter
    # @param value [String] the value of the parameter
    # @return [Array] the resultant parameter string inside an array.
    def use_named_parameter(name, value)
      if value then ["#{name}=#{value}"] else [] end
    end

    # Assemble a url from an array of parts.
    # @param parts [Array] the url chunks to be assembled
    # @return [String] the resultant url string
    def concat_url parts
      if parts.length > 1 then
        parts.first + '?' + parts.drop(1).join('&')
      else
        parts.first
      end
    end

    class << self

      def access_method? meth_id
        @access_methods.include? meth_id
      end

      # Allow certain methods to be accessed
      # without defining "new".
      # @param meth_id [Symbol] symbol defining method requested
      # @param *args Arguments list
      # @return [Boolean]
      def method_missing(meth_id, *args)
        access_method?(meth_id) ? new.send(meth_id, *args) : super
      end

    end

    private

    # Build the API Client
    # @param api_connection [Faraday::Connection,nil] supply mock API Connection
    def start_connection api_connection=nil
      @conn = build_connection(api_connection)
      @conn_no_err = build_connection(api_connection, true)
    end

    def build_connection(api_connection, raise_error=false)
      return api_connection || Faraday.new(Diplomat.configuration.url, Diplomat.configuration.options) do |faraday|
        faraday.adapter  Faraday.default_adapter
        faraday.request  :url_encoded
        faraday.response :raise_error unless raise_error

        Diplomat.configuration.middleware.each do |middleware|
          faraday.use middleware
        end
      end
    end

    # Parse the body, apply it to the raw attribute
    def parse_body
      @raw = JSON.parse(@raw.body)
    end

    # Get the key/value(s) from the raw output
    #
    #
    #
    # @param [bool] is_recurse, true if we're handling the result of a recursive search
    # @returns [String|Array] a string equal to the value if it was a regular get and there is
    #                         a result, otherwise, an array of hashes, where the hash contains
    #                         :key & :value entries. When nothing was found, either for a recursive
    #                         search or for a regular one, we return an empty array
    def return_value is_recurse
      if @raw.count == 1 && !is_recurse
        @value = @raw.first["Value"]
        @value = Base64.decode64(@value) unless @value.nil?
      else
        @value = @raw.reduce([]) do |acc, e|
          acc << {
            :key => e["Key"],
            :value => Base64.decode64(e["Value"])
          } unless e["Value"].nil?
          acc
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
