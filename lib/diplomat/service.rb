require 'base64'
require 'faraday'

module Diplomat
  class Service < Diplomat::RestClient

    # Get a service by it's key
    # @param key [String] the key
    # @param scope [Symbol] :first or :all results
    # @param options [Hash] :wait string for wait time and :index for index of last query
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all data associated with the service
    def get key, scope=:first, options=nil, meta=nil

      qs = ""
      sep = "?"
      if options and options[:wait]
        qs = "#{qs}#{sep}wait=#{options[:wait]}"
        sep = "&"
      end
      if options and options[:index]
        qs = "#{qs}#{sep}index=#{options[:index]}"
        sep = "&"
      end
      if options and options[:tags]
        tags = options[:tags].gsub(',','&tag=')
        qs = "#{qs}#{sep}tag=#{tags}"
        sep = "&"
      end

      ret = @conn.get "/v1/catalog/service/#{key}#{qs}"

      if meta and ret.headers
        meta[:index] = ret.headers["x-consul-index"]
        meta[:knownleader] = ret.headers["x-consul-knownleader"]
        meta[:lastcontact] = ret.headers["x-consul-lastcontact"]
      end

      if scope == :all
        return JSON.parse(ret.body).map { |service| OpenStruct.new service }
      end
      return OpenStruct.new JSON.parse(ret.body).first
    end

    # @note This is sugar, see (#get)
    def self.get *args
      Diplomat::Service.new.get *args
    end

  end
end
