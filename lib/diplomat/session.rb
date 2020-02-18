# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul session API endpoint
  class Session < Diplomat::RestClient
    @access_methods = %i[create destroy list renew info node]

    # Create a new session
    # @param value [Object] hash or json representation of the session arguments
    # @param options [Hash] session options
    # @return [String] The sesssion id
    def create(value = nil, options = {})
      # TODO: only certain keys are recognised in a session create request,
      # should raise an error on others.
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      data = value.is_a?(String) ? value : JSON.generate(value) unless value.nil?
      raw = send_put_request(@conn, ['/v1/session/create'], options, data, custom_params)
      body = JSON.parse(raw.body)
      body['ID']
    end

    # Destroy a session
    # @param id [String] session id
    # @param options [Hash] session options
    # @return [String] Success or failure of the session destruction
    def destroy(id, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      raw = send_put_request(@conn, ["/v1/session/destroy/#{id}"], options, nil, custom_params)
      raw.body
    end

    # List sessions
    # @param options [Hash] session options
    # @return [OpenStruct]
    def list(options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      raw = send_get_request(@conn, ['/v1/session/list'], options, custom_params)
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end

    # Renew session
    # @param id [String] session id
    # @param options [Hash] session options
    # @return [OpenStruct]
    def renew(id, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      raw = send_put_request(@conn, ["/v1/session/renew/#{id}"], options, nil, custom_params)
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end

    # Session information
    # @param id [String] session id
    # @param options [Hash] session options
    # @return [OpenStruct]
    def info(id, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      raw = send_get_request(@conn, ["/v1/session/info/#{id}"], options, custom_params)
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end

    # Session information for a given node
    # @param name [String] node name
    # @param options [Hash] session options
    # @return [OpenStruct]
    def node(name, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      raw = send_get_request(@conn, ["/v1/session/node/#{name}"], options, custom_params)
      JSON.parse(raw.body).map { |session| OpenStruct.new session }
    end
  end
end
