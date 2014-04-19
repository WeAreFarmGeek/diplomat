require 'base64'
require 'faraday'

module Diplomat
  class Kv < Diplomat::RestClient

    attr_reader :key, :value, :raw

    def get key
      @key   = key
      @raw   = @conn.get "/v1/kv/#{@key}"
      @raw   = JSON.parse @raw
      @value = Base64.decode64(@raw["Value"])
      return @value
    end

    def put key, value
      @raw   = @conn.put "/v1/kv/#{@key}", @value
      @raw   = JSON.parse @raw
      @key   = @raw["Key"]
      @value = Base64.decode64(@raw["Value"])
      return @value
    end

    def delete key
      @raw = @conn.delete "/v1/kv/#{@key}"
      @key   = nil
      @value = nil
    end

    def self.get *args
      Diplomat::Kv.new.get *args
    end

    def self.put *args
      Diplomat::Kv.new.put *args
    end

    def self.delete *args
      Diplomat::Kv.new.delete *args
    end


  end
end
