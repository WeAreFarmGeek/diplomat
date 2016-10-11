require 'base64'
require 'faraday'

module Diplomat
  class Agent < Diplomat::RestClient
    @access_methods = [:self, :checks, :services, :members]

    # Get agent configuration
    # @return [OpenStruct] all data associated with the node
    def self
      url = ['/v1/agent/self']

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      JSON.parse(ret.body).tap { |node| OpenStruct.new node }
    end

    # Get local agent checks
    # @return [OpenStruct] all agent checks
    def checks
      url = ['/v1/agent/checks']

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      JSON.parse(ret.body).tap { |node| OpenStruct.new node }
    end

    # Get local agent services
    # @return [OpenStruct] all agent services
    def services
      url = ['/v1/agent/services']

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      JSON.parse(ret.body).tap { |node| OpenStruct.new node }
    end

    # Get cluster members (as seen by the agent)
    # @return [OpenStruct] all members
    def members
      url = ['/v1/agent/members']

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      JSON.parse(ret.body).map { |node| OpenStruct.new node }
    end
  end
end
