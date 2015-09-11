require 'base64'
require 'faraday'

module Diplomat
  class Datacenter < Diplomat::RestClient
    @access_methods = [:get]

    # Get an array of all avaliable datacenters accessible by the local consul agent
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all datacenters avaliable to this consul agent
    def get(meta = nil)
      url = ['/v1/catalog/datacenters']

      ret = @conn.get concat_url url

      if meta && ret.headers
        meta[:index] = ret.headers['x-consul-index']
        meta[:knownleader] = ret.headers['x-consul-knownleader']
        meta[:lastcontact] = ret.headers['x-consul-lastcontact']
      end
      JSON.parse(ret.body)
    end
  end
end
