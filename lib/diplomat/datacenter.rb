module Diplomat
  # Methods for interacting with the Consul dataceneter API endpoint
  class Datacenter < Diplomat::RestClient
    @access_methods = [:get]

    # Get an array of all avaliable datacenters accessible by the local consul agent
    # @param meta [Hash] output structure containing header information about the request (index)
    # @return [OpenStruct] all datacenters avaliable to this consul agent
    def get(meta = nil, options = nil)
      url = ['/v1/catalog/datacenters']
      url << use_consistency(options) if use_consistency(options, nil)

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
