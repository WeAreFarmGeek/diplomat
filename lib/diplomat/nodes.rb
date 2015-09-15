require 'base64'
require 'faraday'

module Diplomat
  class Nodes < Diplomat::RestClient
    @access_methods = [ :get ]

    # Get all nodes
    # @return [OpenStruct] all data associated with the service
    def get
      ret = @conn.get "/v1/catalog/nodes"
      return JSON.parse(ret.body)
    end
  end
end
