module Diplomat
  # Methods for interacting with the Consul members API endpoint
  class Members < Diplomat::RestClient
    @access_methods = [:get]

    # Get all members
    # @return [OpenStruct] all data associated with the service
    def get
      ret = @conn.get '/v1/agent/members'
      JSON.parse(ret.body)
    end
  end
end
