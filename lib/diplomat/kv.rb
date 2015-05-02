require 'base64'
require 'faraday'

module Diplomat
  class Kv < Diplomat::RestClient

    attr_reader :key, :value, :raw

    # Get a value by its key, potentially blocking for the first or next value
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [String] :consistency The read consistency type
    # @param not_found [Symbol] behaviour if the key doesn't exist;
    #   :reject with exception, or :wait for it to appear
    # @param found [Symbol] behaviour if the key does exist;
    #   :reject with exception, :wait for its next value, or :return its current value
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
    #   - W X - get the first value only (must not have a current value)
    #   - W R - get the first or current value; always return something, but
    #           block only when necessary
    #   - W W - get the first or next value; wait until there is an update
    def get key, options=nil, not_found=:reject, found=:return
      @key = key
      @options = options

      url = ["/v1/kv/#{@key}"]
      url += check_acl_token
      url += use_consistency(@options)

      # 404s OK using this connection
      raw = @conn_no_err.get concat_url url
      if raw.status == 404
        case not_found
          when :reject
            raise Diplomat::KeyNotFound, key
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
            return return_value
          when :wait
            index = raw.headers["x-consul-index"]
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}"
      end

      # Wait for first/next value
      url = ["/v1/kv/#{@key}"]
      url += check_acl_token
      url += use_consistency(@options)
      url += use_named_parameter("index", index)
      @raw = @conn.get do |req|
        req.url concat_url url
        req.options.timeout = 86400
      end
      parse_body
      return_value
    end

    # Associate a value with a key
    # @param key [String] the key
    # @param value [String] the value
    # @param options [Hash] the query params
    # @option options [Integer] :cas The modify index
    # @return [Bool] Success or failure of the write (can fail in c-a-s mode)
    def put key, value, options=nil
      @options = options
      @raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += check_acl_token
        url += use_cas(@options)
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
    # @return [OpenStruct]
    def delete key
      @key = key
      url = ["/v1/kv/#{@key}"]
      url += check_acl_token
      @raw = @conn.delete concat_url url
    end

    # @note This is sugar, see (#get)
    def self.get *args
      Diplomat::Kv.new.get *args
    end

    # @note This is sugar, see (#put)
    def self.put *args
      Diplomat::Kv.new.put *args
    end

    # @note This is sugar, see (#delete)
    def self.delete *args
      Diplomat::Kv.new.delete *args
    end

    private

    # Parse the body, apply it to the raw attribute
    def parse_body
      @raw = JSON.parse(@raw.body)
    end

    # Get the key from the raw output
    def return_key
      @key = @raw["Key"]
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
                     :value => e["Value"].nil? ? e["Value"] : Base64.decode64(e["Value"])
                   }
                 end
      end
    end

    def check_acl_token
      use_named_parameter("token", Diplomat.configuration.acl_token)
    end

    def use_cas(options)
      if options then use_named_parameter("cas", options[:cas]) else [] end
    end

    def use_consistency(options)
      if options && options[:consistency] then ["#{options[:consistency]}"] else [] end
    end
  end
end
