# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul status API endpoints, leader and peers
  class Status < Diplomat::RestClient
    @access_methods = %i[leader peers]

    # Get the raft leader for the datacenter in which the local consul agent is running
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] the address of the leader
    def leader(options = {})
      ret = send_get_request(@conn, ['/v1/status/leader'], options)
      JSON.parse(ret.body)
    end

    # Get an array of Raft peers for the datacenter in which the agent is running
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] an array of peers
    def peers(options = {})
      ret = send_get_request(@conn, ['/v1/status/peers'], options)
      JSON.parse(ret.body)
    end
  end
end
