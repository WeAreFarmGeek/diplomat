module Diplomat
  # Methods for interacting with the Consul serivce API endpoint.
  class Service < Diplomat::RestClient
    include ApiOptions

    @access_methods = %i[get get_all register deregister register_external deregister_external maintenance]

    # Get a service by it's key
    # @param key [String] the key
    # @param scope [Symbol] :first or :all results
    # @param options [Hash] options parameter hash
    # @option wait [Integer] :wait string for wait time
    # @option index [String] :index for index of last query
    # @option dc [String] :dc data center to make request for
    # @option tag [String] :tag service tag to get
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all data associated with the service
    # rubocop:disable PerceivedComplexity, MethodLength, CyclomaticComplexity, AbcSize
    def get(key, scope = :first, options = nil, meta = nil)
      url = ["/v1/catalog/service/#{key}"]
      url += check_acl_token
      url << use_named_parameter('wait', options[:wait]) if options && options[:wait]
      url << use_named_parameter('index', options[:index]) if options && options[:index]
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      url << use_named_parameter('tag', options[:tag]) if options && options[:tag]

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError => e
        raise Diplomat::PathNotFound, e
      end

      if meta && ret.headers
        meta[:index] = ret.headers['x-consul-index']
        meta[:knownleader] = ret.headers['x-consul-knownleader']
        meta[:lastcontact] = ret.headers['x-consul-lastcontact']
      end

      if scope == :all
        JSON.parse(ret.body).map { |service| OpenStruct.new service }
      else
        OpenStruct.new JSON.parse(ret.body).first
      end
    end
    # rubocop:enable PerceivedComplexity, MethodLength, CyclomaticComplexity, AbcSize

    # Get all the services
    # @param options [Hash] :dc Consul datacenter to query
    # @return [OpenStruct] the list of all services
    def get_all(options = nil)
      url = ['/v1/catalog/services']
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end

      OpenStruct.new JSON.parse(ret.body)
    end

    # Register a service
    # @param definition [Hash] Hash containing definition of service
    # @return [Boolean]
    def register(definition, path = '/v1/agent/service/register')
      json_definition = JSON.dump(definition)
      register = @conn.put path, json_definition
      register.status == 200
    end

    # De-register a service
    # @param service_name [String] Service name to de-register
    # @return [Boolean]
    def deregister(service_name)
      deregister = @conn.get "/v1/agent/service/deregister/#{service_name}"
      deregister.status == 200
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
      deregister.status == 200
    end

    # Enable or disable maintenance for a service
    # @param [Hash] opts the options for enabling or disabling maintenance for a service
    # @options opts [Boolean] :enable (true) whether to enable or disable maintenance
    # @options opts [String] :reason reason for the service maintenance
    # @raise [Diplomat::PathNotFound] if the request fails
    # @return [Boolean] if the request was successful or not
    # rubocop:disable AbcSize
    def maintenance(service_id, options = { enable: true })
      url = ["/v1/agent/service/maintenance/#{service_id}"]
      url += check_acl_token
      url << ["enable=#{options[:enable]}"]
      url << ["reason=#{options[:reason].split(' ').join('+')}"] if options && options[:reason]
      begin
        maintenance = @conn.put concat_url(url)
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      maintenance.status == 200
    end
    # rubocop:enable AbcSize
  end
end
