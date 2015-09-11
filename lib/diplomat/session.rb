require 'faraday'

module Diplomat
  class Session < Diplomat::RestClient
    @access_methods = [:create, :destroy, :list, :renew]

    # Create a new session
    # @param value [Object] hash or json representation of the session arguments
    # @return [String] The sesssion id
    def create(value = nil)
      # TODO: only certain keys are recognised in a session create request,
      # should raise an error on others.
      raw = @conn.put do |req|
        req.url '/v1/session/create'
        unless value.nil?
          value.is_a?(String) ? req.body = value : req.body = JSON.generate(value)
        end
      end
      body = JSON.parse(raw.body)
      body['ID']
    end

    # Destroy a session
    # @param id [String] session id
    # @return [nil]
    def destroy(id)
      raw = @conn.put do |req|
        req.url "/v1/session/destroy/#{id}"
      end
      raw.body
    end

    # List sessions
    # @return [Struct]
    def list
      raw = @conn.get do |req|
        req.url '/v1/session/list'
      end
      JSON.parse(raw.body)
    end

    # Renew session
    # @param id [String] session id
    # @return [Struct]

    def renew(id)
      raw = @conn.put do |req|
        req.url "/v1/session/renew/#{id}"
      end
      JSON.parse(raw.body)
    end
  end
end
