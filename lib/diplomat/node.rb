require 'base64'
require 'faraday'

module Diplomat
  class Node < Diplomat::RestClient

    # Get a node by it's name
    # @param key [String] the key
    # @param scope [Symbol] :first or :all results
    # @param options [Hash] :wait string for wait time and :index for index of last query
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all data associated with the service
    def get name, options=nil, meta=nil

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

      ret = @conn.get "/v1/catalog/node/#{name}"

      if meta and ret.headers
        meta[:index] = ret.headers["x-consul-index"]
        meta[:knownleader] = ret.headers["x-consul-knownleader"]
        meta[:lastcontact] = ret.headers["x-consul-lastcontact"]
      end

      return OpenStruct.new JSON.parse(ret.body)
    end

    def local *args
      # Get name of local node
      ret = @conn.get '/v1/agent/self'
      node = OpenStruct.new JSON.parse(ret.body)
      localNodeName = node.Config['NodeName']
      Diplomat::Node.new.get localNodeName, *args
    end

    def self.local *args
      # Get name of local node
      Diplomat::Node.new.local *args
    end

    # @note This is sugar, see (#get)
    def self.get *args
      Diplomat::Node.new.get *args
    end

  end
end