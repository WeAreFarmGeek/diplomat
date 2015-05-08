require 'faraday'

module Diplomat
  class Session < Diplomat::RestClient

    @access_methods = [ :create, :destroy ]

    # Create a new session
    # @param value [Object] hash or json representation of the session arguments
    # @return [String] The sesssion id
    def create value=nil
      # TODO: only certain keys are recognised in a session create request,
      # should raise an error on others.
      raw = @conn.put do |req|
        req.url "/v1/session/create"
        req.body = (if value.kind_of?(String) then value else JSON.generate(value) end) unless value.nil?
      end
      body = JSON.parse(raw.body)
      return body["ID"]
    end

    # Destroy a session
    # @param id [String] session id
    # @return [nil]
    def destroy id
      raw = @conn.put do |req|
        req.url "/v1/session/destroy/#{id}"
      end
      return raw.body
    end
  end
end
