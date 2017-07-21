module Diplomat
  # Base class for interacting with the Consul RESTful API
  class RestClient
    @access_methods = []

    # Initialize the fadaray connection
    # @param api_connection [Faraday::Connection,nil] supply mock API Connection
    def initialize(api_connection = nil)
      start_connection api_connection
    end

    # Format url parameters into strings correctly
    # @param name [String] the name of the parameter
    # @param value [String] the value of the parameter
    # @return [Array] the resultant parameter string inside an array.
    def use_named_parameter(name, value)
      value ? ["#{name}=#{value}"] : []
    end

    # Assemble a url from an array of parts.
    # @param parts [Array] the url chunks to be assembled
    # @return [String] the resultant url string
    def concat_url(parts)
      if parts.length > 1
        parts.first + '?' + parts.drop(1).join('&')
      else
        parts.first
      end
    end

    class << self
      def access_method?(meth_id)
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
    def start_connection(api_connection = nil)
      @conn = build_connection(api_connection)
      @conn_no_err = build_connection(api_connection, true)
    end

    def build_connection(api_connection, raise_error = false)
      api_connection || Faraday.new(Diplomat.configuration.url, Diplomat.configuration.options) do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
        faraday.response :raise_error unless raise_error

        Diplomat.configuration.middleware.each do |middleware|
          faraday.use middleware
        end
      end
    end

    # Converts k/v data into ruby hash
    # rubocop:disable MethodLength, AbcSize
    def convert_to_hash(data)
      collection = []
      master     = {}
      data.each do |item|
        split_up = item[:key].split('/')
        sub_hash = {}
        temp = nil
        real_size = split_up.size - 1
        (0..real_size).each do |i|
          if i.zero?
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
        master = deep_merge(master, h)
      end
      master
    end
    # rubocop:enable MethodLength, AbcSize

    def deep_merge(first, second)
      merger = proc { |_key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
      first.merge(second, &merger)
    end

    # Parse the body, apply it to the raw attribute
    def parse_body
      return JSON.parse(@raw.body) if @raw.status == 200
      raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
    end

    # Return @raw with Value fields decoded
    def decode_values
      return @raw if @raw.first.is_a? String
      @raw.each_with_object([]) do |acc, el|
        acc['Value'] = Base64.decode64(acc['Value']) rescue nil # rubocop:disable RescueModifier
        el << acc
        el
      end
    end

    # Get the key/value(s) from the raw output
    # rubocop:disable PerceivedComplexity, MethodLength, CyclomaticComplexity, AbcSize
    def return_value(nil_values = false, transformation = nil, return_hash = false)
      @value = decode_values
      return @value if @value.first.is_a? String
      if @value.count == 1 && !return_hash
        @value = @value.first['Value']
        @value = transformation.call(@value) if transformation && !@value.nil?
        return @value
      else
        @value = @value.map do |el|
          el['Value'] = transformation.call(el['Value']) if transformation && !el['Value'].nil?
          { key: el['Key'], value: el['Value'] } if el['Value'] || nil_values
        end.compact
      end
    end
    # rubocop:enable PerceivedComplexity, MethodLength, CyclomaticComplexity, AbcSize

    # Get the name and payload(s) from the raw output
    def return_payload
      @value = @raw.map do |e|
        { name: e['Name'],
          payload: (Base64.decode64(e['Payload']) unless e['Payload'].nil?) }
      end
    end
  end
end
