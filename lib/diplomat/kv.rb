module Diplomat
  # Methods for interacting with the Consul KV API endpoint
  class Kv < Diplomat::RestClient
    include ApiOptions

    @access_methods = %i[get put delete txn]
    attr_reader :key, :value, :raw

    # Get a value by its key, potentially blocking for the first or next value
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [Boolean] :recurse If to make recursive get or not
    # @option options [String] :consistency The read consistency type
    # @option options [String] :dc Target datacenter
    # @option options [Boolean] :keys Only return key names.
    # @option options [Boolean] :modify_index Only return ModifyIndex value.
    # @option options [Boolean] :decode_values Return consul response with decoded values.
    # @option options [String] :separator List only up to a given separator.
    #   Only applies when combined with :keys option.
    # @option options [Boolean] :nil_values If to return keys/dirs with nil values
    # @option options [Boolean] :convert_to_hash Take the data returned from consul and build a hash
    # @option options [Callable] :transformation funnction to invoke on keys values
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
    # rubocop:disable PerceivedComplexity, MethodLength, CyclomaticComplexity, AbcSize, LineLength
    def get(key, options = nil, not_found = :reject, found = :return)
      @key = key
      @options = options

      url = ["/v1/kv/#{@key}"]
      url += recurse_get(@options)
      url += check_acl_token
      url += use_consistency(@options)
      url += dc(@options)
      url += keys(@options)
      url += separator(@options)

      return_nil_values = @options && @options[:nil_values]
      transformation = @options && @options[:transformation] && @options[:transformation].methods.find_index(:call) ? @options[:transformation] : nil

      # 404s OK using this connection
      raw = @conn_no_err.get concat_url url
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
      url += use_named_parameter('index', index)
      @raw = @conn.get do |req|
        req.url concat_url url
        req.options.timeout = 86_400
      end
      @raw = parse_body
      return_value(return_nil_values, transformation)
    end
    # rubocop:enable PerceivedComplexity, MethodLength, CyclomaticComplexity, AbcSize, LineLength

    # Associate a value with a key
    # @param key [String] the key
    # @param value [String] the value
    # @param options [Hash] the query params
    # @option options [Integer] :cas The modify index
    # @option options [String] :dc Target datacenter
    # @return [Bool] Success or failure of the write (can fail in c-a-s mode)
    # rubocop:disable MethodLength, AbcSize
    def put(key, value, options = nil)
      @options = options
      @raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += check_acl_token
        url += use_cas(@options)
        url += dc(@options)
        req.url concat_url url
        req.body = value
      end
      if @raw.body.chomp == 'true'
        @key = key
        @value = value
      end
      @raw.body.chomp == 'true'
    end
    # rubocop:enable MethodLength, AbcSize

    # Delete a value by its key
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [String] :dc Target datacenter
    # @option options [Boolean] :recurse If to make recursive get or not
    # @return [OpenStruct]
    def delete(key, options = nil)
      @key = key
      @options = options
      url = ["/v1/kv/#{@key}"]
      url += recurse_get(@options)
      url += check_acl_token
      url += dc(@options)
      @raw = @conn.delete concat_url url
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
    def txn(value, options = nil)
      # Verify the given value for the transaction
      transaction_verification(value)
      # Will return 409 if transaction was rolled back
      raw = @conn_no_err.put do |req|
        url = ['/v1/txn']
        url += check_acl_token
        url += dc(options)
        url += transaction_consistency(options)

        req.url concat_url url
        req.body = JSON.generate(value)
      end
      transaction_return JSON.parse(raw.body), options
    end

    private

    def recurse_get(options)
      options && options[:recurse] ? ['recurse'] : []
    end

    def dc(options)
      options && options[:dc] ? use_named_parameter('dc', options[:dc]) : []
    end

    def keys(options)
      options && options[:keys] ? ['keys'] : []
    end

    def separator(options)
      options && options[:separator] ? use_named_parameter('separator', options[:separator]) : []
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
        options && options[:decode_values] == false ? raw_return : decode_transaction(raw_return)
      OpenStruct.new decoded_return
    end

    def decode_transaction(transaction)
      return transaction if transaction['Results'].nil? || transaction['Results'].empty?

      transaction.tap do |txn|
        txn['Results'].each do |resp|
          next unless resp['KV']['Value']
          value = resp['KV']['Value']
          resp['KV']['Value'] = Base64.decode64(value) rescue nil # rubocop:disable RescueModifier
        end
      end
    end
  end
end
