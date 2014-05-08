require 'base64'
require 'faraday'

module Diplomat
  class Members < Diplomat::RestClient

    # Get all members
    # @return [OpenStruct] all data associated with the service
    def get
      ret = @conn.get "/v1/agent/members"
      return JSON.parse(ret.body)
    end

    # @note This is sugar, see (#get)
    def self.get
      Diplomat::Members.new.get
    end

  end
end
