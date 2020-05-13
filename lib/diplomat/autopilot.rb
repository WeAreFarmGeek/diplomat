# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul operator autopilot API endpoint
  class Autopilot < Diplomat::RestClient
    @access_methods = %i[get_configuration get_health update]

    # Get autopilot configuration
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the autopilot configuration
    def get_configuration(options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]

      ret = send_get_request(@conn, ['/v1/operator/autopilot/configuration'], options, custom_params)
      JSON.parse(ret.body)
    end

    # Get health status from the autopilot
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the health of the autopilot
    def get_health(options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]

      ret = send_get_request(@conn, ['/v1/operator/autopilot/health'], options, custom_params)
      JSON.parse(ret.body)
    end
  end
end
