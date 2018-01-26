module Diplomat
  # Methods for interacting with the Consul node API endpoint
  class Node < Diplomat::RestClient
    include ApiOptions

    @access_methods = %i[get get_all register deregister]

    # Get a node by it's key
    # @param key [String] the key
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def get(key, options = nil)
      url = ["/v1/catalog/node/#{key}"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      ret = @conn.get concat_url url
      OpenStruct.new JSON.parse(ret.body)
    rescue Faraday::ClientError
      raise Diplomat::PathNotFound
    end

    # Get all the nodes
    # @param options [Hash]
    #   :dc string for dc specific query
    #   :meta hash for metadata query
    # @return [OpenStruct] the list of all nodes
    def get_all(options = nil) # rubocop:disable Metrics/AbcSize
      url = ['/v1/catalog/nodes']
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      url << options[:meta].map { |m| use_named_parameter('node-meta', m.join(':')) } if options && options[:meta]

      ret = @conn.get concat_url url
      JSON.parse(ret.body).map { |service| OpenStruct.new service }
    rescue Faraday::ClientError
      raise Diplomat::PathNotFound
    end

    # Register a node
    # @param definition [Hash] Hash containing definition of a node to register
    # @return [Boolean]
    def register(definition, path = '/v1/catalog/register')
      register = @conn.put path, JSON.dump(definition)

      register.status == 200
    end

    # De-register a node (and all associated services and checks)
    # @param definition [Hash] Hash containing definition of a node to de-register
    # @return [Boolean]
    def deregister(definition, path = '/v1/catalog/deregister')
      deregister = @conn.put path, JSON.dump(definition)

      deregister.status == 200
    end
  end
end
