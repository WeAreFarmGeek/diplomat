require 'base64'
require 'faraday'

module Diplomat
  class Health < Diplomat::RestClient
    @access_methods = [ :node, :checks, :service, :state,
                        :any, :passing, :warning, :critical ]

    # Get node health
    # @param n [String] the node
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def node n, options=nil
      url = ["/v1/health/node/#{n}"]
      url << use_named_parameter('dc', options[:dc]) if options and options[:dc]

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      return JSON.parse(ret.body).map { |node| OpenStruct.new node }
    end

    # Get service checks
    # @param s [String] the service
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def checks s, options=nil
      url = ["/v1/health/checks/#{s}"]
      url << use_named_parameter('dc', options[:dc]) if options and options[:dc]
      
      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error.
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      return JSON.parse(ret.body).map { |check| OpenStruct.new check }
    end

    # Get service health
    # @param s [String] the service
    # @param options [Hash] :dc string for dc specific query
    # @param options [Hash] :passing boolean to return only checks in passing state
    # @param options [Hash] :tag string for specific tag
    # @return [OpenStruct] all data associated with the node
    def service s, options=nil
      url = ["/v1/health/service/#{s}"]
      url << use_named_parameter('dc', options[:dc]) if options and options[:dc]
      url << 'passing' if options and options[:passing]
      url << use_named_parameter('tag', options[:tag]) if options and options[:tag]
      url << use_named_parameter('near', options[:near]) if options and options[:near]

      # If the request fails, it's probably due to a bad path
      # so return a PathNotFound error. 
      begin
        ret = @conn.get concat_url url
      rescue Faraday::ClientError
        raise Diplomat::PathNotFound
      end
      return JSON.parse(ret.body).map { |service| OpenStruct.new service }
    end

    # Get service health
    # @param s [String] the state ("any", "passing", "warning", or "critical")
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the node
    def state s, options=nil
       url = ["/v1/health/state/#{s}"]
       url << use_named_parameter('dc', options[:dc]) if options and options[:dc]
       url << use_named_parameter('near', options[:near]) if options and options[:near]
       
       # If the request fails, it's probably due to a bad path
       # so return a PathNotFound error.
       begin
         ret = @conn.get concat_url url
       rescue Faraday::ClientError
         raise Diplomat::PathNotFound
       end
       return JSON.parse(ret.body).map { |status| OpenStruct.new status }
    end

    # Convenience method to get services in any state
    def any
      state('any')
    end

    # Convenience method to get services in passing state
    def passing
      state('passing')
    end

    # Convenience method to get services in warning state
    def warning
      state('warning')
    end

    # Convenience method to get services in critical state
    def critical
      state('critical')
    end
  end
end
