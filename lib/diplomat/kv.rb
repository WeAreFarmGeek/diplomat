# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul KV API endpoint
  class Kv < Diplomat::RestClient
    @access_methods = %i[get get_all put delete txn]
    attr_reader :key, :value, :raw

    # Get a value by its key, potentially blocking for the first or next value
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [Boolean] :recurse If to make recursive get or not
    # @option options [String] :consistency The read consistency type
    # @option options [String] :dc Target datacenter
    # @option options [Boolean] :keys Only return key names.
    # @option options [Boolean] :modify_index Only return ModifyIndex value.
    # @option options [Boolean] :session Only return Session value.
    # @option options [Boolean] :decode_values Return consul response with decoded values.
    # @option options [String] :separator List only up to a given separator.
    #   Only applies when combined with :keys option.
    # @option options [Boolean] :nil_values If to return keys/dirs with nil values
    # @option options [Boolean] :convert_to_hash Take the data returned from consul and build a hash
    # @option options [Callable] :transformation function to invoke on keys values
    # @param not_found [Symbol] behaviour if the key doesn't exist;
    #   :reject with exception, :return degenerate value, or :wait for it to appear
    # @param found [Symbol] behaviour if the key does exist;
    #   :reject with exception, :return its current value, or :wait for its next value
    # @return [String] The base64-decoded value associated with the key
    # @note
    #   When trying to access a key, there are two possibilites:
    #   - The key doesn't (yet) exist
    #   - The key exists. This may be its first value, there is no way to tell
    #   The combination of not_found and found behaviour gives maximum possible
    #   flexibility. For X: reject, R: return, W: wait
    #   - X X - meaningless; never return a value
    #   - X R - "normal" non-blocking get operation. Default
    #   - X W - get the next value only (must have a current value)
    #   - R X - meaningless; never return a meaningful value
    #   - R R - "safe" non-blocking, non-throwing get-or-default operation
    #   - R W - get the next value or a default
    #   - W X - get the first value only (must not have a current value)
    #   - W R - get the first or current value; always return something, but
    #           block only when necessary
    #   - W W - get the first or next value; wait until there is an update
    # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Layout/LineLength, Metrics/CyclomaticComplexity
    def get(key, options = {}, not_found = :reject, found = :return)
      @options = options
      return_nil_values = @options && @options[:nil_values]
      transformation = @options && @options[:transformation] && @options[:transformation].methods.find_index(:call) ? @options[:transformation] : nil
      raw = get_raw(key, options)

      if raw.status == 404
        case not_found
        when :reject
          raise Diplomat::KeyNotFound, key
        when :return
          return @value = ''
        when :wait
          index = raw.headers['x-consul-index']
        end
      elsif raw.status == 200
        case found
        when :reject
          raise Diplomat::KeyAlreadyExists, key
        when :return
          @raw = raw
          @raw = parse_body
          return @raw.first['ModifyIndex'] if @options && @options[:modify_index]
          return @raw.first['Session'] if @options && @options[:session]
          return decode_values if @options && @options[:decode_values]
          return convert_to_hash(return_value(return_nil_values, transformation, true)) if @options && @options[:convert_to_hash]

          return return_value(return_nil_values, transformation)
        when :wait
          index = raw.headers['x-consul-index']
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}: #{raw.body}"
      end

      # Wait for first/next value
      @raw = wait_for_value(index, options)
      @raw = parse_body
      return_value(return_nil_values, transformation)
    end
    # rubocop:enable Metrics/PerceivedComplexity, Layout/LineLength, Metrics/MethodLength, Metrics/CyclomaticComplexity

    # Get all keys recursively, potentially blocking for the first or next value
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [String] :consistency The read consistency type
    # @option options [String] :dc Target datacenter
    # @option options [Boolean] :keys Only return key names.
    # @option options [Boolean] :decode_values Return consul response with decoded values.
    # @option options [String] :separator List only up to a given separator.
    #   Only applies when combined with :keys option.
    # @option options [Boolean] :nil_values If to return keys/dirs with nil values
    # @option options [Boolean] :convert_to_hash Take the data returned from consul and build a hash
    # @option options [Callable] :transformation function to invoke on keys values
    # @param not_found [Symbol] behaviour if the key doesn't exist;
    #   :reject with exception, :return degenerate value, or :wait for it to appear
    # @param found [Symbol] behaviour if the key does exist;
    #   :reject with exception, :return its current value, or :wait for its next value
    # @return [List] List of hashes, one hash for each key-value returned
    # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength, Layout/LineLength, Metrics/CyclomaticComplexity
    def get_all(key, options = {}, not_found = :reject, found = :return)
      @options = options
      @options[:recurse] = true
      return_nil_values = @options && @options[:nil_values]
      transformation = @options && @options[:transformation] && @options[:transformation].methods.find_index(:call) ? @options[:transformation] : nil

      raw = get_raw(key, options)
      if raw.status == 404
        case not_found
        when :reject
          raise Diplomat::KeyNotFound, key
        when :return
          return @value = []
        when :wait
          index = raw.headers['x-consul-index']
        end
      elsif raw.status == 200
        case found
        when :reject
          raise Diplomat::KeyAlreadyExists, key
        when :return
          @raw = raw
          @raw = parse_body
          return decode_values if @options && @options[:decode_values]
          return convert_to_hash(return_value(return_nil_values, transformation, true)) if @options && @options[:convert_to_hash]

          return return_value(return_nil_values, transformation, true)
        when :wait
          index = raw.headers['x-consul-index']
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}: #{raw.body}"
      end

      # Wait for first/next value
      @raw = wait_for_value(index, options)
      @raw = parse_body
      return_value(return_nil_values, transformation, true)
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength, Layout/LineLength, Metrics/CyclomaticComplexity

    # Associate a value with a key
    # @param key [String] the key
    # @param value [String] the value
    # @param options [Hash] the query params
    # @option options [Integer] :cas The modify index
    # @option options [String] :dc Target datacenter
    # @option options [String] :acquire Session to attach to key
    # @return [Bool] Success or failure of the write (can fail in c-a-s mode)
    def put(key, value, options = {})
      key = normalize_key_for_uri(key)
      @options = options
      custom_params = []
      custom_params << use_cas(@options)
      custom_params << dc(@options)
      custom_params << acquire(@options)
      @raw = send_put_request(@conn, ["/v1/kv/#{key}"], options, value, custom_params,
                              'application/x-www-form-urlencoded')
      if @raw.body.chomp == 'true'
        @key = key
        @value = value
      end
      @raw.body.chomp == 'true'
    end

    # Delete a value by its key
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [String] :dc Target datacenter
    # @option options [Boolean] :recurse If to make recursive get or not
    # @return [OpenStruct]
    def delete(key, options = {})
      key = normalize_key_for_uri(key)
      @key = key
      @options = options
      custom_params = []
      custom_params << recurse_get(@options)
      custom_params << dc(@options)
      @raw = send_delete_request(@conn, ["/v1/kv/#{@key}"], options, custom_params)
    end

    # Perform a key/value store transaction.
    #
    # @since 1.3.0
    # @see https://www.consul.io/docs/agent/http/kv.html#txn Transaction key/value store API documentation
    # @example Valid key/value store transaction format
    #   [
    #     {
    #       'KV' => {
    #         'Verb' => 'get',
    #         'Key' => 'hello/world'
    #       }
    #     }
    #   ]
    # @raise [Diplomat::InvalidTransaction] if transaction format is invalid
    # @param value [Array] an array of transaction hashes
    # @param [Hash] options transaction params
    # @option options [Boolean] :decode_values of any GET requests, default: true
    # @option options [String] :dc Target datacenter
    # @option options [String] :consistency the accepted staleness level of the transaction.
    #   Can be 'stale' or 'consistent'
    # @return [OpenStruct] result of the transaction
    def txn(value, options = {})
      # Verify the given value for the transaction
      transaction_verification(value)
      # Will return 409 if transaction was rolled back
      custom_params = []
      custom_params << dc(options)
      custom_params << transaction_consistency(options)
      raw = send_put_request(@conn_no_err, ['/v1/txn'], options, value, custom_params)
      transaction_return JSON.parse(raw.body), options
    end

    private

    def get_raw(key, options = {}, custom_params = [])
      key = normalize_key_for_uri(key)
      @key = key
      @options = options
      custom_params << recurse_get(@options)
      custom_params << use_consistency(@options)
      custom_params << dc(@options)
      custom_params << keys(@options)
      custom_params << separator(@options)

      send_get_request(@conn_no_err, ["/v1/kv/#{@key}"], options, custom_params)
    end

    def wait_for_value(index, options)
      custom_params = []
      custom_params << use_named_parameter('index', index)
      if options.nil?
        options = { timeout: 86_400 }
      else
        options[:timeout] = 86_400
      end
      get_raw(key, options, custom_params)
    end

    def recurse_get(options)
      options[:recurse] ? ['recurse'] : []
    end

    def dc(options)
      options[:dc] ? use_named_parameter('dc', options[:dc]) : []
    end

    def acquire(options)
      options[:acquire] ? use_named_parameter('acquire', options[:acquire]) : []
    end

    def keys(options)
      options[:keys] ? ['keys'] : []
    end

    def separator(options)
      options[:separator] ? use_named_parameter('separator', options[:separator]) : []
    end

    def transaction_consistency(options)
      return [] unless options

      if options[:consistency] && options[:consistency] == 'stale'
        ['stale']
      elsif options[:consistency] && options[:consistency] == 'consistent'
        ['consistent']
      else
        []
      end
    end

    def transaction_verification(transaction)
      raise Diplomat::InvalidTransaction unless transaction.is_a?(Array)

      transaction.each do |req|
        raise Diplomat::InvalidTransaction unless transaction_type_verification(req)
        raise Diplomat::InvalidTransaction unless transaction_verb_verification(req['KV'])
      end
      # Encode all value transacations if all checks pass
      encode_transaction(transaction)
    end

    def transaction_type_verification(txn)
      txn.is_a?(Hash) && txn.keys == %w[KV]
    end

    def transaction_verb_verification(txn)
      transaction_verb = txn['Verb']
      raise Diplomat::InvalidTransaction unless valid_transaction_verbs.include? transaction_verb

      test_requirements = valid_transaction_verbs[transaction_verb] - txn.keys
      test_requirements.empty?
    end

    def encode_transaction(transaction)
      transaction.each do |txn|
        next unless valid_value_transactions.include? txn['KV']['Verb']

        value = txn['KV']['Value']
        txn['KV']['Value'] = Base64.encode64(value).chomp
      end
    end

    def transaction_return(raw_return, options)
      decoded_return =
        options[:decode_values] == false ? raw_return : decode_transaction(raw_return)
      OpenStruct.new decoded_return
    end

    def decode_transaction(transaction)
      return transaction if transaction['Results'].nil? || transaction['Results'].empty?

      transaction.tap do |txn|
        txn['Results'].each do |resp|
          next unless resp['KV']['Value']

          begin
            resp['KV']['Value'] = Base64.decode64(resp['KV']['Value'])
          rescue StandardError
            nil
          end
        end
      end
    end
  end
end
