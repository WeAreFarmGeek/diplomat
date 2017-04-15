module Diplomat
  # Methods to interact with the Consul maintenance API endpoint
  class Maintenance < Diplomat::RestClient
    @access_methods = %i[enabled enable]

    # Get the maintenance state of a host
    # @param n [String] the node
    # @param options [Hash] :dc string for dc specific query
    # @return [Hash] { :enabled => true, :reason => 'foo' }
    def enabled(n, options = nil)
      health = Diplomat::Health.new(@conn)
      result = health.node(n, options)
                     .select { |check| check['CheckID'] == '_node_maintenance' }

      if result.empty?
        { enabled: false, reason: nil }
      else
        { enabled: true, reason: result.first['Notes'] }
      end
    end

    # Enable or disable maintenance mode.  This endpoint only works
    # on the local agent.
    # @param enable enable or disable maintenance mode
    # @param reason [String] the reason for enabling maintenance mode
    # @param options [Hash] :dc string for dc specific query
    # @return true if call is successful
    # rubocop:disable AbcSize
    def enable(enable = true, reason = nil, options = nil)
      raw = @conn.put do |req|
        url = ['/v1/agent/maintenance']
        url << use_named_parameter('enable', enable.to_s)
        url << use_named_parameter('reason', reason) if reason
        url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
        req.url concat_url url
      end

      return_status = raw.status == 200
      raise Diplomat::UnknownStatus, "status #{raw.status}: #{raw.body}" unless return_status
      return_status
    end
    # rubocop:enable AbcSize
  end
end
