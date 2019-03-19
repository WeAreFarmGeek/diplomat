require 'deep_merge'

module Diplomat
  # Base class for interacting with the Consul RESTful API
  class RestClient
    @access_methods = []
    @configuration = nil

    # Initialize the fadaray connection
    # @param api_connection [Faraday::Connection,nil] supply mock API Connection
    # @param configuration [Diplomat::Configuration] a dedicated config to use
    def initialize(api_connection = nil, configuration: nil)
      @configuration = configuration
      start_connection api_connection
    end

    # Get client configuration or global one if not specified via initialize.
    # @return [Diplomat::Configuration] used by this client
    def configuration
      @configuration || ::Diplomat.configuration
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
      parts.reject!(&:empty?)
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
      api_connection || Faraday.new(configuration.url, configuration.options) do |faraday|
        configuration.middleware.each do |middleware|
          faraday.use middleware
        end

        faraday.request  :url_encoded
        faraday.response :raise_error unless raise_error

        faraday.adapter  Faraday.default_adapter
      end
    end

    # Converts k/v data into ruby hash
    def convert_to_hash(data)
      data.map do |item|
        item[:key].split('/').reverse.reduce(item[:value]) { |h, v| { v => h } }
      end.reduce(:deep_merge)
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
        begin
          acc['Value'] = Base64.decode64(acc['Value'])
        rescue StandardError
          nil
        end
        el << acc
        el
      end
    end

    # Get the key/value(s) from the raw output
    # rubocop:disable PerceivedComplexity
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
    # rubocop:enable PerceivedComplexity

    # Get the name and payload(s) from the raw output
    def return_payload
      @value = @raw.map do |e|
        { name: e['Name'],
          payload: (Base64.decode64(e['Payload']) unless e['Payload'].nil?) }
      end
    end

    def use_cas(options)
      options ? use_named_parameter('cas', options[:cas]) : []
    end

    def use_consistency(options)
      options[:consistency] ? [options[:consistency].to_s] : []
    end

    # rubocop:disable PerceivedComplexity
    # TODO: Migrate all custom params in options
    def parse_options(options)
      headers = nil
      query_params = []
      url_prefix = nil
      consistency = []

      # Parse options used as header
      headers = { 'X-Consul-Token' => configuration.acl_token } if configuration.acl_token
      headers = { 'X-Consul-Token' => options[:token] } if options[:token]

      # Parse options used as query params
      consistency = 'stale' if options[:stale]
      consistency = 'leader' if options[:leader]
      consistency = 'consistent' if options[:consistent]
      query_params << consistency

      # Parse url host
      url_prefix = options[:http_addr] if options[:http_addr]
      { query_params: query_params, headers: headers, url_prefix: url_prefix }
    end
    # rubocop:enable PerceivedComplexity

    def send_get_request(connection, url, options, custom_params = nil)
      rest_options = parse_options(options)
      url += rest_options[:query_params]
      url += custom_params unless custom_params.nil?
      begin
        connection.get do |req|
          req.url rest_options[:url_prefix] ? rest_options[:url_prefix] + concat_url(url) : concat_url(url)
          rest_options[:headers].map { |k, v| req.headers[k.to_sym] = v } unless rest_options[:headers].nil?
          req.options.timeout = options[:timeout] if options[:timeout]
        end
      rescue Faraday::ClientError => e
        raise Diplomat::PathNotFound, e
      end
    end

    def send_put_request(connection, url, options, data, custom_params = nil)
      rest_options = parse_options(options)
      url += rest_options[:query_params]
      url += custom_params unless custom_params.nil?
      connection.put do |req|
        req.url rest_options[:url_prefix] ? rest_options[:url_prefix] + concat_url(url) : concat_url(url)
        rest_options[:headers].map { |k, v| req.headers[k.to_sym] = v } unless rest_options[:headers].nil?
        req.body = data unless data.nil?
      end
    end

    def send_post_request(connection, url, options, data, custom_params = nil)
      rest_options = parse_options(options)
      url += rest_options[:query_params]
      url += custom_params unless custom_params.nil?
      connection.post do |req|
        req.url rest_options[:url_prefix] ? rest_options[:url_prefix] + concat_url(url) : concat_url(url)
        rest_options[:headers].map { |k, v| req.headers[k.to_sym] = v } unless rest_options[:headers].nil?
        req.body = JSON.dump(data) unless data.nil?
      end
    end

    def send_delete_request(connection, url, options, custom_params = nil)
      rest_options = parse_options(options)
      url += rest_options[:query_params]
      url += custom_params unless custom_params.nil?
      connection.delete do |req|
        req.url rest_options[:url_prefix] ? rest_options[:url_prefix] + concat_url(url) : concat_url(url)
        rest_options[:headers].map { |k, v| req.headers[k.to_sym] = v } unless rest_options[:headers].nil?
      end
    end

    # Mapping for valid key/value store transaction verbs and required parameters
    #
    # @return [Hash] valid key/store transaction verbs and required parameters
    def valid_transaction_verbs
      {
        'set' => %w[Key Value],
        'cas' => %w[Key Value Index],
        'lock' => %w[Key Value Session],
        'unlock' => %w[Key Value Session],
        'get' => %w[Key],
        'get-tree' => %w[Key],
        'check-index' => %w[Key Index],
        'check-session' => %w[Key Session],
        'delete' => %w[Key],
        'delete-tree' => %w[Key],
        'delete-cas' => %w[Key Index]
      }
    end

    # Key/value store transactions that require that a value be set
    #
    # @return [Array<String>] verbs that require a value be set
    def valid_value_transactions
      @valid_value_transactions ||= valid_transaction_verbs.select do |verb, requires|
        verb if requires.include? 'Value'
      end
    end
  end
end
