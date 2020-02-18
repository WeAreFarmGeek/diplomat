# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul node API endpoint
  class Node < Diplomat::RestClient
    @access_methods = %i[get get_all register deregister]

    # Get a node by it's key
    # @param key [String] the key
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def get(key, options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_get_request(@conn, ["/v1/catalog/node/#{key}"], options, custom_params)
      OpenStruct.new JSON.parse(ret.body)
    end

    # Get all the nodes
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] the list of all nodes
    def get_all(options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_get_request(@conn, ['/v1/catalog/nodes'], options, custom_params)
      JSON.parse(ret.body).map { |service| OpenStruct.new service }
    end

    # Register a node
    # @param definition [Hash] Hash containing definition of a node to register
    # @param options [Hash] options parameter hash
    # @return [Boolean]
    def register(definition, options = {})
      register = send_put_request(@conn, ['/v1/catalog/register'], options, definition)
      register.status == 200
    end

    # De-register a node (and all associated services and checks)
    # @param definition [Hash] Hash containing definition of a node to de-register
    # @param options [Hash] options parameter hash
    # @return [Boolean]
    def deregister(definition, options = {})
      deregister = send_put_request(@conn, ['/v1/catalog/deregister'], options, definition)
      deregister.status == 200
    end
  end
end
