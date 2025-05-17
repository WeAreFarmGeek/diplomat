# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul operator raft API endpoint
  class RaftOperator < Diplomat::RestClient
    @access_methods = %i[get_configuration transfer_leader]

    # Get raft configuration
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the raft configuration
    def get_configuration(options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]

      ret = send_get_request(@conn, ['/v1/operator/raft/configuration'], options, custom_params)
      JSON.parse(ret.body)
    end

    # Transfer raft leadership
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the transfer status
    #         with format {"Success": ["true"|"false"]}
    def transfer_leader(options = {})
      custom_params = options[:id] ? use_named_parameter('id', options[:id]) : nil
      @raw = send_post_request(@conn, ['/v1/operator/raft/transfer-leader'], options, nil, custom_params)
      JSON.parse(@raw.body)
    end
  end
end
