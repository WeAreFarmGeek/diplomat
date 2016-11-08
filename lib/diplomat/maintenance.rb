require 'base64'
require 'faraday'

module Diplomat
  class Maintenance < Diplomat::RestClient
    @access_methods = [ :enabled, :enable]

    # Get the maintenance state of a host
    # @param n [String] the node
    # @param options [Hash] :dc string for dc specific query
    # @return [Hash] { :enabled => true, :reason => 'foo' }
    def enabled n, options=nil
      health = Diplomat::Health.new(@conn)
      result = health.node(n, options).
        select { |check| check['CheckID'] == '_node_maintenance' }

      if result.size > 0
        { :enabled => true, :reason => result.first['Notes'] }
      else
        { :enabled => false, :reason => nil }
      end
    end

    # Enable or disable maintenance mode.  This endpoint only works
    # on the local agent.
    # @param enable enable or disable maintenance mode
    # @param reason [String] the reason for enabling maintenance mode
    # @param options [Hash] :dc string for dc specific query
    # @return true if call is successful
    def enable enable=true, reason=nil, options=nil
      raw = @conn.put do |req|
        url = ["/v1/agent/maintenance"]
        url << use_named_parameter('enable', enable.to_s)
        url << use_named_parameter('reason', reason) unless reason.nil?
        url << use_named_parameter('dc', options[:dc]) if options and options[:dc]
        req.url concat_url url
      end

      if raw.status == 200
        @raw = raw
        return true
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}: #{raw.body}"
      end
    end
  end
end
