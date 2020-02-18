# frozen_string_literal: true

require 'base64'
require 'faraday'

module Diplomat
  # Agent API endpoint methods
  # @see https://www.consul.io/docs/agent/http/agent.html
  class Agent < Diplomat::RestClient
    @access_methods = %i[self checks services members]

    # Get agent configuration
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all data associated with the node
    def self(options = {})
      ret = send_get_request(@conn, ['/v1/agent/self'], options)
      JSON.parse(ret.body).tap { |node| OpenStruct.new node }
    end

    # Get local agent checks
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all agent checks
    def checks(options = {})
      ret = send_get_request(@conn, ['/v1/agent/checks'], options)
      JSON.parse(ret.body).tap { |node| OpenStruct.new node }
    end

    # Get local agent services
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all agent services
    def services(options = {})
      ret = send_get_request(@conn, ['/v1/agent/services'], options)
      JSON.parse(ret.body).tap { |node| OpenStruct.new node }
    end

    # Get cluster members (as seen by the agent)
    # @param options [Hash] options parameter hash
    # @return [OpenStruct] all members
    def members(options = {})
      ret = send_get_request(@conn, ['/v1/agent/members'], options)
      JSON.parse(ret.body).map { |node| OpenStruct.new node }
    end
  end
end
