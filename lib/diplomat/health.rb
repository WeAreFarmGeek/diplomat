require 'base64'
require 'faraday'

module Diplomat
  class Health < Diplomat::RestClient
    @access_methods = [ :node, :checks, :service, :state,
                        :unknown, :passing, :warning, :critical ]

    # Get node health
    # @param n [String] the node
    # @return [OpenStruct] all data associated with the node
    def node n
      ret = @conn.get "/v1/health/node/#{n}"
      return JSON.parse(ret.body)
    end

    # Get service checks
    # @param s [String] the service
    # @return [OpenStruct] all data associated with the node
    def checks s
      ret = @conn.get "/v1/health/checks/#{s}"
      return JSON.parse(ret.body)
    end

    # Get service health
    # @param s [String] the service
    # @return [OpenStruct] all data associated with the node
    def service s
      ret = @conn.get "/v1/health/service/#{s}"
      return JSON.parse(ret.body)
    end

    # Get service health
    # @param s [String] the state ("unknown", "passing", "warning", or "critical")
    # @return [OpenStruct] all data associated with the node
    def state s
      ret = @conn.get "/v1/health/state/#{s}"
      return JSON.parse(ret.body)
    end

    # Convenience method to get services in unknown state
    def unknown
      state("unknown")
    end

    # Convenience method to get services in passing state
    def passing
      state("passing")
    end

    # Convenience method to get services in warning state
    def warning
      state("warning")
    end

    # Convenience method to get services in critical state
    def critical
      state("critical")
    end
  end
end
