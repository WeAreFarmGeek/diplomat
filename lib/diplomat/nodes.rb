require 'base64'
require 'faraday'

module Diplomat
  class Nodes < Diplomat::RestClient
    @access_methods = [ :get ]

    # Get all nodes
    # @deprecated Please use Diplomat::Node instead.
    # @return [OpenStruct] all data associated with the nodes in catalog
    def get
      ret = @conn.get "/v1/catalog/nodes"
      return JSON.parse(ret.body)
    end
  end
end
