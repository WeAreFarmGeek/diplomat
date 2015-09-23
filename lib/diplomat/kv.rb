require 'base64'
require 'faraday'

module Diplomat
  class Kv < Diplomat::RestClient
    @access_methods = [ :get, :put, :delete ]
    attr_reader :key, :value, :raw

    # Get a value by its key, potentially blocking for the first or next value
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [String] :consistency The read consistency type
    # @option options [String] :dc Target datacenter
    # @option options [String] :recurse indicates that we're performing a recursive get
    # @param not_found [Symbol] behaviour if the key doesn't exist;
    #   :reject with exception, :return degenerate value, or :wait for it to appear
    # @param found [Symbol] behaviour if the key does exist;
    #   :reject with exception, :return its current value, or :wait for its next value
    # @return [String|Array] a string equal to the value if it was a regular get and there is
    #                         a result, otherwise, an array of hashes, where the hash contains
    #                         :key & :value entries. When nothing was found, either for a recursive
    #                         search or for a regular one, we return an empty array
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
    def get key, options=nil, not_found=:reject, found=:return
      @key = key
      @options = options

      url = ["/v1/kv/#{@key}"]
      url += recurse_get(@options)
      url += check_acl_token
      url += use_consistency(@options)
      url += dc(@options)

      # We need to know if this is a recursive search so we know how to parse the output. But
      # the user can invoke a recursive get in two ways: (1) by adding '?recurse' to the key
      # string or by adding a {:recurse => true} to the options hash.
      is_recurse = key.end_with?('?recurse') || ( options && options[:recurse] )

      # 404s OK using this connection
      raw = @conn_no_err.get concat_url url
      if raw.status == 404
        case not_found
          when :reject
            raise Diplomat::KeyNotFound, key
          when :return
            return @value = ""
          when :wait
            index = raw.headers["x-consul-index"]
        end
      elsif raw.status == 200
        case found
          when :reject
            raise Diplomat::KeyAlreadyExists, key
          when :return
            @raw = raw
            parse_body
            return return_value is_recurse
          when :wait
            index = raw.headers["x-consul-index"]
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}"
      end

      # Wait for first/next value
      url += use_named_parameter("index", index)
      @raw = @conn.get do |req|
        req.url concat_url url
        req.options.timeout = 86400
      end
      parse_body
      return_value is_recurse
    end

    # Associate a value with a key
    # @param key [String] the key
    # @param value [String] the value
    # @param options [Hash] the query params
    # @option options [Integer] :cas The modify index
    # @option options [String] :dc Target datacenter
    # @return [Bool] Success or failure of the write (can fail in c-a-s mode)
    def put key, value, options=nil
      @options = options
      @raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += check_acl_token
        url += use_cas(@options)
        url += dc(@options)
        req.url concat_url url
        req.body = value
      end
      if @raw.body == "true"
        @key   = key
        @value = value
      end
      @raw.body == "true"
    end

    # Delete a value by its key
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [String] :dc Target datacenter
    # @return [OpenStruct]
    def delete key, options=nil
      @key = key
      @options = options
      url = ["/v1/kv/#{@key}"]
      url += check_acl_token
      url += dc(@options)
      @raw = @conn.delete concat_url url
    end

    private

    def check_acl_token
      use_named_parameter("token", Diplomat.configuration.acl_token)
    end

    def use_cas(options)
      if options then use_named_parameter("cas", options[:cas]) else [] end
    end

    def use_consistency(options)
      if options && options[:consistency] then ["#{options[:consistency]}"] else [] end
    end

    def recurse_get(options)
      if options && options[:recurse] then ['recurse'] else [] end
    end

    def dc(options)
      if options && options[:dc] then use_named_parameter("dc", options[:dc]) else [] end
    end
  end
end
