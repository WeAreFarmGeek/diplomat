# frozen_string_literal: true

module Diplomat
  # @depreciated
  # Methods for interacting with the Consul nodes API endpoint
  class Nodes < Diplomat::RestClient
    @access_methods = %i[get get_all]

    # Get all nodes
    # @deprecated Please use Diplomat::Node instead.
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the nodes in catalog
    def get(options = {})
      ret = send_get_request(@conn, ['/v1/catalog/nodes'], options)
      JSON.parse(ret.body)
    end

    def get_all(options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_get_request(@conn, ['/v1/catalog/nodes'], options, custom_params)
      JSON.parse(ret.body).map { |service| OpenStruct.new service }
    end
  end
end
