module Diplomat
  # Methods for interacting with the Consul status API endpoints, leader and peers
  class Status < Diplomat::RestClient
    @access_methods = %i[leader peers]

    # Get the raft leader for the datacenter in which the local consul agent is running
    # @return [OpenStruct] the address of the leader
    def leader
      url = ['/v1/status/leader']
      ret = @conn.get concat_url url
      JSON.parse(ret.body)
    end

    # Get an array of Raft peers for the datacenter in which the agent is running
    # @return [OpenStruct] an array of peers
    def peers
      url = ['/v1/status/peers']
      ret = @conn.get concat_url url
      JSON.parse(ret.body)
    end
  end
end
