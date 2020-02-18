# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul dataceneter API endpoint
  class Datacenter < Diplomat::RestClient
    @access_methods = [:get]

    # Get an array of all avaliable datacenters accessible by the local consul agent
    # @param meta [Hash] output structure containing header information about the request (index)
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all datacenters avaliable to this consul agent
    def get(meta = nil, options = {})
      ret = send_get_request(@conn, ['/v1/catalog/datacenters'], options)

      if meta && ret.headers
        meta[:index] = ret.headers['x-consul-index'] if ret.headers['x-consul-index']
        meta[:knownleader] = ret.headers['x-consul-knownleader'] if ret.headers['x-consul-knownleader']
        meta[:lastcontact] = ret.headers['x-consul-lastcontact'] if ret.headers['x-consul-lastcontact']
      end
      JSON.parse(ret.body)
    end
  end
end
