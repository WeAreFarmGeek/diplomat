# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul members API endpoint
  class Members < Diplomat::RestClient
    @access_methods = [:get]

    # Get all members
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the service
    def get(options = {})
      ret = send_get_request(@conn, ['/v1/agent/members'], options)
      JSON.parse(ret.body)
    end
  end
end
