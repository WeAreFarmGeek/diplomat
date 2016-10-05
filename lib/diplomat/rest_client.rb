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
        if access_method?(meth_id)
          new.send(meth_id, *args)
        else

          # See https://bugs.ruby-lang.org/issues/10969
          begin
            super
          rescue NameError => err
            raise NoMethodError, err
          end
        end
      end

      # Make `respond_to?` aware of method short-cuts.
      #
      # @param meth_id [Symbol] the tested method
      # @oaram with_private if private methods should be tested too
      def respond_to?(meth_id, with_private = false)
        access_method?(meth_id) || super
      end

      # Make `respond_to_missing` aware of method short-cuts. This is needed for
      # {#method} to work on these, which is helpful for testing purposes.
      #
      # @param meth_id [Symbol] the tested method
      # @oaram with_private if private methods should be tested too
      def respond_to_missing?(meth_id, with_private = false)
        access_method?(meth_id) || super
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

    #Converts k/v data into ruby hash
    def convert_to_hash(data)
      collection = []
      master     = {}
      data.each do |item|
        split_up = item[:key].split ?/
        sub_hash = {}
        temp = nil
        real_size = split_up.size - 1
        for i in 0..real_size do
           if i == 0
              temp = {}
              sub_hash[split_up[i]] = temp
              next
           end
           if i == real_size
              temp[split_up[i]] = item[:value]
           else
              new_h = {}
              temp[split_up[i]] = new_h
              temp = new_h
           end
         end
         collection << sub_hash
      end

      collection.each do |h|
         n = deep_merge(master, h)
         master = n
      end
      master
    end

    def deep_merge(first, second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
        first.merge(second, &merger)
    end

    # Parse the body, apply it to the raw attribute
    def parse_body
      return JSON.parse(@raw.body) if @raw.status == 200
      raise Diplomat::UnknownStatus, "status #{@raw.status}"
    end

    # Return @raw with Value fields decoded
    def decode_values
      return @raw if @raw.first.is_a? String
      @raw.inject([]) do |acc, el|
        new_el = el.dup
        new_el["Value"] = (Base64.decode64(el["Value"]) rescue nil)
        acc << new_el
        acc
      end
    end

    # Get the key/value(s) from the raw output
    def return_value(nil_values=false, transformation=nil)
      @value = decode_values
      if @value.first.is_a? String
        return @value
      elsif @value.count == 1
        @value = @value.first["Value"]
        @value = transformation.call(@value) if transformation and not @value.nil?
        return @value
      else
        @value = @value.map do |el|
          el["Value"] = transformation.call(el["Value"]) if transformation and not el["Value"].nil?
          { :key => el["Key"], :value => el["Value"] } if el["Value"] or nil_values
        end.compact
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
