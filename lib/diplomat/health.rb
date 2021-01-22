# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul health API endpoint
  class Health < Diplomat::RestClient
    @access_methods = %i[node checks service state
                         any passing warning critical]

    # Get node health
    # @param n [String] the node
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def node(n, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]

      ret = send_get_request(@conn, ["/v1/health/node/#{n}"], options, custom_params)
      JSON.parse(ret.body).map { |node| OpenStruct.new node }
    end

    # Get service checks
    # @param s [String] the service
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def checks(s, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]

      ret = send_get_request(@conn, ["/v1/health/checks/#{s}"], options, custom_params)
      JSON.parse(ret.body).map { |check| OpenStruct.new check }
    end

    # Get service health
    # @param s [String] the service
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the node
    # rubocop:disable Metrics/PerceivedComplexity
    def service(s, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << ['passing'] if options[:passing]
      custom_params += [*options[:tag]].map { |value| use_named_parameter('tag', value) } if options[:tag]
      custom_params << use_named_parameter('near', options[:near]) if options[:near]
      custom_params << use_named_parameter('node-meta', options[:node_meta]) if options[:node_meta]

      ret = send_get_request(@conn, ["/v1/health/service/#{s}"], options, custom_params)
      JSON.parse(ret.body).map { |service| OpenStruct.new service }
    end

    # rubocop:enable Metrics/PerceivedComplexity

    # Get service health
    # @param s [String] the state ("any", "passing", "warning", or "critical")
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def state(s, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('near', options[:near]) if options[:near]

      ret = send_get_request(@conn, ["/v1/health/state/#{s}"], options, custom_params)
      JSON.parse(ret.body).map { |status| OpenStruct.new status }
    end

    # Convenience method to get services in any state
    def any
      state('any')
    end

    # Convenience method to get services in passing state
    def passing
      state('passing')
    end

    # Convenience method to get services in warning state
    def warning
      state('warning')
    end

    # Convenience method to get services in critical state
    def critical
      state('critical')
    end
  end
end
