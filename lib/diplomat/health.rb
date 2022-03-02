# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul health API endpoint
  class Health < Diplomat::RestClient
    @access_methods = %i[node checks service state
                         any passing warning critical]

    # Get node health
    # @param n [String] the node
    # @param options [Hash] :dc, :filter string for specific query
    # @return [OpenStruct] all data associated with the node
    def node(n, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('filter', options[:filter]) if options[:filter]

      ret = send_get_request(@conn, ["/v1/health/node/#{n}"], options, custom_params)
      JSON.parse(ret.body).map { |node| OpenStruct.new node }
    end

    # Get service checks
    # @param s [String] the service
    # @param options [Hash] :dc, :filter string for specific query
    # @return [OpenStruct] all data associated with the node
    def checks(s, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('filter', options[:filter]) if options[:filter]

      ret = send_get_request(@conn, ["/v1/health/checks/#{s}"], options, custom_params)
      JSON.parse(ret.body).map { |check| OpenStruct.new check }
    end

    # Get service health
    # @param s [String] the service
    # @param options [Hash] options parameter hash
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all data associated with the node
    # rubocop:disable Metrics/PerceivedComplexity
    def service(s, options = {}, meta = nil)
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << ['passing'] if options[:passing]
      custom_params += [*options[:tag]].map { |value| use_named_parameter('tag', value) } if options[:tag]
      custom_params << use_named_parameter('near', options[:near]) if options[:near]
      custom_params << use_named_parameter('node-meta', options[:node_meta]) if options[:node_meta]
      custom_params << use_named_parameter('index', options[:index]) if options[:index]
      custom_params << use_named_parameter('filter', options[:filter]) if options[:filter]

      ret = send_get_request(@conn, ["/v1/health/service/#{s}"], options, custom_params)
      if meta && ret.headers
        meta[:index] = ret.headers['x-consul-index'] if ret.headers['x-consul-index']
        meta[:knownleader] = ret.headers['x-consul-knownleader'] if ret.headers['x-consul-knownleader']
        meta[:lastcontact] = ret.headers['x-consul-lastcontact'] if ret.headers['x-consul-lastcontact']
      end

      JSON.parse(ret.body).map { |service| OpenStruct.new service }
    end

    # rubocop:enable Metrics/PerceivedComplexity

    # Get service health
    # @param s [String] the state ("any", "passing", "warning", or "critical")
    # @param options [Hash] :dc, :near, :filter string for specific query
    # @return [OpenStruct] all data associated with the node
    def state(s, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('near', options[:near]) if options[:near]
      custom_params << use_named_parameter('filter', options[:filter]) if options[:filter]

      ret = send_get_request(@conn, ["/v1/health/state/#{s}"], options, custom_params)
      JSON.parse(ret.body).map { |status| OpenStruct.new status }
    end

    # Convenience method to get services in any state
    # @param options [Hash] :dc, :near, :filter string for specific query
    # @return [OpenStruct] all data associated with the node
    def any(options = {})
      state('any', options)
    end

    # Convenience method to get services in passing state
    # @param options [Hash] :dc, :near, :filter string for specific query
    # @return [OpenStruct] all data associated with the node
    def passing(options = {})
      state('passing', options)
    end

    # Convenience method to get services in warning state
    # @param options [Hash] :dc, :near, :filter string for specific query
    # @return [OpenStruct] all data associated with the node
    def warning(options = {})
      state('warning', options)
    end

    # Convenience method to get services in critical state
    # @param options [Hash] :dc, :near, :filter string for specific query
    # @return [OpenStruct] all data associated with the node
    def critical(options = {})
      state('critical', options)
    end
  end
end
