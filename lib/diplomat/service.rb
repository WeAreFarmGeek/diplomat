# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul service API endpoint.
  class Service < Diplomat::RestClient
    @access_methods = %i[get get_all register deregister register_external deregister_external maintenance]

    # Get a service by it's key
    # @param key [String] the key
    # @param scope [Symbol] :first or :all results
    # @param options [Hash] options parameter hash
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all data associated with the service
    # rubocop:disable Metrics/PerceivedComplexity
    def get(key, scope = :first, options = {}, meta = nil)
      custom_params = []
      custom_params << use_named_parameter('wait', options[:wait]) if options[:wait]
      custom_params << use_named_parameter('index', options[:index]) if options[:index]
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('filter', options[:filter]) if options[:filter]
      custom_params += [*options[:tag]].map { |value| use_named_parameter('tag', value) } if options[:tag]

      ret = send_get_request(@conn, ["/v1/catalog/service/#{key}"], options, custom_params)
      if meta && ret.headers
        meta[:index] = ret.headers['x-consul-index'] if ret.headers['x-consul-index']
        meta[:knownleader] = ret.headers['x-consul-knownleader'] if ret.headers['x-consul-knownleader']
        meta[:lastcontact] = ret.headers['x-consul-lastcontact'] if ret.headers['x-consul-lastcontact']
      end

      if scope == :all
        JSON.parse(ret.body).map { |service| OpenStruct.new service }
      else
        OpenStruct.new JSON.parse(ret.body).first
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # Get all the services
    # @param options [Hash] :dc Consul datacenter to query
    # @return [OpenStruct] the list of all services
    def get_all(options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_get_request(@conn, ['/v1/catalog/services'], options, custom_params)
      OpenStruct.new JSON.parse(ret.body)
    end

    # Register a service
    # @param definition [Hash] Hash containing definition of service
    # @param options [Hash] options parameter hash
    # @return [Boolean]
    def register(definition, options = {})
      url = options[:path] || ['/v1/agent/service/register']
      register = send_put_request(@conn, url, options, definition)
      register.status == 200
    end

    # De-register a service
    # @param service_name [String] Service name to de-register
    # @param options [Hash] options parameter hash
    # @return [Boolean]
    def deregister(service_name, options = {})
      deregister = send_put_request(@conn, ["/v1/agent/service/deregister/#{service_name}"], options, nil)
      deregister.status == 200
    end

    # Register an external service
    # @param definition [Hash] Hash containing definition of service
    # @param options [Hash] options parameter hash
    # @return [Boolean]
    def register_external(definition, options = {})
      register = send_put_request(@conn, ['/v1/catalog/register'], options, definition)
      register.status == 200
    end

    # Deregister an external service
    # @param definition [Hash] Hash containing definition of service
    # @param options [Hash] options parameter hash
    # @return [Boolean]
    def deregister_external(definition, options = {})
      deregister = send_put_request(@conn, ['/v1/catalog/deregister'], options, definition)
      deregister.status == 200
    end

    # Enable or disable maintenance for a service
    # @param service_id [String] id of the service
    # @param options [Hash] opts the options for enabling or disabling maintenance for a service
    # @options opts [Boolean] :enable (true) whether to enable or disable maintenance
    # @options opts [String] :reason reason for the service maintenance
    # @raise [Diplomat::PathNotFound] if the request fails
    # @return [Boolean] if the request was successful or not
    def maintenance(service_id, options = { enable: true })
      custom_params = []
      custom_params << ["enable=#{options[:enable]}"]
      custom_params << ["reason=#{options[:reason].split(' ').join('+')}"] if options[:reason]
      maintenance = send_put_request(@conn, ["/v1/agent/service/maintenance/#{service_id}"],
                                     options, nil, custom_params)
      maintenance.status == 200
    end
  end
end
