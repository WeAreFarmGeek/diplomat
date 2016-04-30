require 'base64'
require 'faraday'

module Diplomat
  class Node < Diplomat::RestClient

    include ApiOptions

    @access_methods = [ :get, :get_all ]

    # Get a node by it's key
    # @param key [String] the key
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def get key, options=nil

      url = ["/v1/catalog/node/#{key}"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options and options[:dc]

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      return JSON.parse(ret.body)
    end

    # Get all the nodes
    # @return [OpenStruct] the list of all nodes
    def get_all
      url = "/v1/catalog/nodes"
      begin
        ret = @conn.get url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end

      return JSON.parse(ret.body).map { |service| OpenStruct.new service }
    end
  end
end
