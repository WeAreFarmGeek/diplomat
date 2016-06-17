require 'base64'
require 'faraday'

module Diplomat
  class Service < Diplomat::RestClient

    include ApiOptions

    @access_methods = [ :get, :get_all, :register, :deregister, :register_external, :deregister_external ]

    # Get a service by it's key
    # @param key [String] the key
    # @param scope [Symbol] :first or :all results
    # @param options [Hash] :wait string for wait time and :index for index of last query
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all data associated with the service
    def get key, scope=:first, options=nil, meta=nil

      url = ["/v1/catalog/service/#{key}"]
      url += check_acl_token
      url << use_named_parameter('wait', options[:wait]) if options and options[:wait]
      url << use_named_parameter('index', options[:index]) if options and options[:index]
      url << use_named_parameter('dc', options[:dc]) if options and options[:dc]
      url << use_named_parameter('tag', options[:tag]) if options and options[:tag]

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError => e
        raise Diplomat::PathNotFound, e
      end

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

    # Get all the services
    # @param options [Hash] :dc Consul datacenter to query
    # @return [OpenStruct] the list of all services
    def get_all options=nil
      url = ["/v1/catalog/services"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options and options[:dc]
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end

      return OpenStruct.new JSON.parse(ret.body)
    end

    # Register a service
    # @param definition [Hash] Hash containing definition of service
    # @return [Boolean]
    def register(definition, path='/v1/agent/service/register')
      json_definition = JSON.dump(definition)
      register = @conn.put path, json_definition
      return register.status == 200
    end

    # De-register a service
    # @param service_name [String] Service name to de-register
    # @return [Boolean]
    def deregister(service_name)
      deregister = @conn.get "/v1/agent/service/deregister/#{service_name}"
      return deregister.status == 200
    end

    # Register an external service
    # @param definition [Hash] Hash containing definition of service
    # @return [Boolean]
    def register_external(definition)
      register(definition, '/v1/catalog/register')
    end

    # Deregister an external service
    # @param definition [Hash] Hash containing definition of service
    # @return [Boolean]
    def deregister_external(definition)
      json_definition = JSON.dump(definition)
      deregister = @conn.put '/v1/catalog/deregister', json_definition
      return deregister.status == 200
    end
  end
end
