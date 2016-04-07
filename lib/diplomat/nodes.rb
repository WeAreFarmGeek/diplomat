require 'base64'
require 'faraday'

module Diplomat
  class Nodes < Diplomat::RestClient
    @access_methods = [ :get, :get_all ]

    # Get all nodes
    # @deprecated Please use Diplomat::Node instead.
    # @return [OpenStruct] all data associated with the nodes in catalog
    def get
      ret = @conn.get "/v1/catalog/nodes"
      return JSON.parse(ret.body)
    end
    
    def get_all options=nil
      url = ["/v1/catalog/nodes"]
      url << use_named_parameter('dc', options[:dc]) if options and options[:dc]
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      return JSON.parse(ret.body).map { |service| OpenStruct.new service }
    end 
  end
end
