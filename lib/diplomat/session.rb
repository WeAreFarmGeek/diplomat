require 'faraday'

module Diplomat
  class Session < Diplomat::RestClient

    @access_methods = [ :create, :destroy, :list, :renew ]

    # Create a new session
    # @param value [Object] hash or json representation of the session arguments
    # @param options [Hash] options
    # @option options [String] :dc DC in which to  create the session
    # @return [String] The sesssion id
    def create value=nil, options={}
      # TODO: only certain keys are recognised in a session create request,
      # should raise an error on others.
      raw = @conn.put do |req|
        url = ["/v1/session/create"]
        url += use_named_parameter('dc', options[:dc])

        req.url concat_url url
        req.body = (if value.kind_of?(String) then value else JSON.generate(value) end) unless value.nil?
      end
      body = JSON.parse(raw.body)
      return body["ID"]
    end

    # Destroy a session
    # @param id [String] session id
    # @param options [Hash] options
    # @option options [String] :dc DC in which to destroy the session
    # @return [nil]
    def destroy id, options={}
      raw = @conn.put do |req|
        url = ["/v1/session/destroy/#{id}"]
        url += use_named_parameter('dc', options[:dc])

        req.url concat_url url
      end
      return raw.body
    end
    
    # List sessions
    # @param options [Hash] options
    # @option options [String] :dc DC in which to list sessions
    # @return [Struct]
    def list options={}
      raw = @conn.get do |req|
        url = ["/v1/session/list"]
        url += use_named_parameter('dc', options[:dc])

        req.url concat_url url
      end
      JSON.parse(raw.body)
    end
    
    # Renew session
    # @param id [String] session id
    # @param options [Hash] options
    # @option options [String] :dc DC in which to renew the session
    # @return [Struct]
    def renew id, options={}
      raw = @conn.put do |req|
        url = ["/v1/session/renew/#{id}"]
        url += use_named_parameter('dc', options[:dc])

        req.url concat_url url
      end
      JSON.parse(raw.body)
    end
  end
end
