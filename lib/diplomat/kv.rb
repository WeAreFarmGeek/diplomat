require 'base64'
require 'faraday'

module Diplomat
  class Kv < Diplomat::RestClient

    attr_reader :key, :value, :raw

    # Get a value by its key
    # @param key [String] the key
    # @return [String] The base64-decoded value associated with the key
    def get key
      @key = key
      url = ["/v1/kv/#{@key}"]
      url += check_acl_token unless check_acl_token.nil?
      @raw = @conn.get concat_url url
      parse_body
      return_value
    end

    # Associate a value with a key
    # @param key [String] the key
    # @param value [String] the value
    # @param options [Hash] the query params
    # @option options [Integer] :cas The modify index
    # @return [String] The base64-decoded value associated with the key
    def put key, value, options=nil
      @options = options
      @raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += check_acl_token unless check_acl_token.nil?
        url += use_cas(@options) unless use_cas(@options).nil?
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
    # @return [nil]
    def delete key
      @key = key
      url = ["/v1/kv/#{@key}"]
      url += check_acl_token unless check_acl_token.nil?
      @raw = @conn.delete concat_url url
      nil
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
      @raw = JSON.parse(@raw.body).first
    end

    # Get the key from the raw output
    def return_key
      @key = @raw["Key"]
    end

    # Get the value from the raw output
    def return_value
      @value = @raw["Value"]
      @value = Base64.decode64(@value) unless @value.nil?
    end

    def check_acl_token
      ["token=#{Diplomat.configuration.acl_token}"] if Diplomat.configuration.acl_token
    end

    def use_cas(options)
      ["cas=#{options[:cas]}"] if options && options[:cas]
    end
  end
end
