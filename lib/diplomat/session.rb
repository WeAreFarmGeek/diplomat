module Diplomat
  # Methods for interacting with the Consul session API endpoint
  class Session < Diplomat::RestClient
    @access_methods = [:create, :destroy, :list, :renew, :info, :node]

    # Create a new session
    # @param value [Object] hash or json representation of the session arguments
    # @param options [Hash] session options
    # @param options [String] :dc datacenter to create session for
    # @return [String] The sesssion id
    def create(value = nil, options = nil)
      # TODO: only certain keys are recognised in a session create request,
      # should raise an error on others.
      raw = @conn.put do |req|
        url = ['/v1/session/create']
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
        req.body = (value.is_a?(String) ? value : JSON.generate(value)) unless value.nil?
      end
      body = JSON.parse(raw.body)
      body['ID']
    end

    # Destroy a session
    # @param id [String] session id
    # @param options [Hash] session options
    # @param options [String] :dc datacenter to destroy session for
    # @return [String] Success or failure of the session destruction
    def destroy(id, options = nil)
      raw = @conn.put do |req|
        url = ["/v1/session/destroy/#{id}"]
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
      end
      raw.body
    end

    # List sessions
    # @param options [Hash] session options
    # @param options [String] :dc datacenter to list sessions
    # @return [OpenStruct]
    def list(options = nil)
      raw = @conn.get do |req|
        url = ['/v1/session/list']
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
      end
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end

    # Renew session
    # @param id [String] session id
    # @param options [Hash] session options
    # @param options [String] :dc datacenter to renew session for
    # @return [OpenStruct]
    def renew(id, options = nil)
      raw = @conn.put do |req|
        url = ["/v1/session/renew/#{id}"]
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
      end
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end

    # Session information
    # @param id [String] session id
    # @param options [Hash] session options
    # @param options [String] :dc datacenter to renew session for
    # @return [OpenStruct]
    def info(id, options = nil)
      raw = @conn.get do |req|
        url = ["/v1/session/info/#{id}"]
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
      end
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end

    # Session information for a given node
    # @param name [String] node name
    # @param options [Hash] session options
    # @param options [String] :dc datacenter to renew session for
    # @return [OpenStruct]
    def node(name, options = nil)
      raw = @conn.get do |req|
        url = ["/v1/session/node/#{name}"]
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
      end
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end
  end
end
