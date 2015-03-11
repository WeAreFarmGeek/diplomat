require 'faraday'

module Diplomat
  class Session < Diplomat::RestClient

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

    # @note This is sugar, see (#create)
    def self.create *args
      Diplomat::Session.new.create *args
    end

    # @note This is sugar, see (#destroy)
    def self.destroy *args
      Diplomat::Session.new.destroy *args
    end
  end
end
