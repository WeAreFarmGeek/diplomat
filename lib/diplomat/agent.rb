module Diplomat
  # Methods to interact with the agent API endpoint
  class Agent < Diplomat::RestClient
    include ApiOptions

    @access_methods = [
      :checks,
      :services,
      :members,
      :self,
      :reload,
      :maintenance,
      :join,
      :leave,
      :force_leave,
      :register_check,
      :deregister_check,
      :pass_check,
      :warn_check,
      :fail_check,
      :update_check,
      :register_service,
      :deregister_service,
      :service_maintenance
    ]

    # Returns the checks associated to this node
    # @return [OpenStruct] all checks associated with the node
    def checks
      url = ['/v1/agent/checks']
      url += check_acl_token

      ret = @conn.get concat_url url
      JSON.parse ret.body
    end

    # Returns the services associated to this node
    # @return [OpenStruct] all services associated with the node
    def services
      url = ['/v1/agent/services']
      url += check_acl_token

      ret = @conn.get concat_url url
      JSON.parse ret.body
    end

    # Returns the members of the cluster
    # @return [OpenStruct] all the cluster membets
    def members
      url = ['/v1/agent/members']
      url += check_acl_token

      ret = @conn.get concat_url url
      [JSON.parse(ret.body)].flatten(1).each { |mbr| OpenStruct.new mbr }
    end

    # Returns the actual configuration of the node
    # @return [OpenStruct] the configuration of the node
    def self
      url = ['/v1/agent/self']
      url += check_acl_token

      ret = @conn.get concat_url url
      OpenStruct.new JSON.parse(ret.body)
    end

    # Triggers the reload of the agent's configuration
    # @return [Boolean] Wether or  not the operation has succeeded
    def reload
      url = ['/v1/agent/reload']
      url += check_acl_token

      ret = @conn.put concat_url url
      ret.status == 200
    end

    # Puts the agent in maintenance mode, or take it out of it
    # @param enable [Boolean] Enable or disable maintenance
    # @param reason [String] Reason behind the maintenance (useless if enable == false)
    # @return [Boolean] Wether the operation has succeeded
    def maintenance(enable = true, reason = nil)
      url = ['/v1/agent/maintenance']
      url += check_acl_token
      url << use_named_parameter('enable', enable.to_s)
      url << use_named_parameter('reason', reason) if reason

      ret = @conn.put concat_url url
      ret.status == 200
    end

    # Makes the agent join another node
    # @param address [String] Other node to join
    # @param wan [Integer] Wether or not this is a WAN node (1 or 0)
    def join(address, wan = 0)
      url = ["/v1/agent/join/#{address}"]
      url += check_acl_token
      url << use_named_parameter('wan', wan) if wan != 0

      ret = @conn.get concat_url url
      ret.status == 200
    end

    # Makes the agent leave the cluster
    # @return [Boolean] Wether or not the operation succeeded
    def leave
      url = ['/v1/agent/leave']
      url += check_acl_token

      ret = @conn.put concat_url url
      ret.status == 200
    end

    # Makes a node leave the cluster
    # @param node [String] Node to force-leave
    # @return [Boolean] Wether or not the operation succeded
    def force_leave(node)
      url = ["/v1/agent/force-leave/#{node}"]
      url += check_acl_token

      ret = @conn.put concat_url url
      ret.status == 200
    end

    # Registers a check
    # @param definition [Hash] The check definition, refer to Consul doc: https://www.consul.io/docs/agent/http/agent.html#agent_check_register
    # @return [Boolean] Wether or not the operation succeeded
    def register_check(definition)
      url = ['/v1/agent/check/register']
      url += check_acl_token

      j = JSON.dump(definition)
      ret = @conn.put concat_url(url), j
      ret.status == 200
    end

    # Deregisters a check
    # @param check [String] The checkID to deregister
    # @return  [Boolean] Wether or not the operation succeeded
    def deregister_check(check)
      url = ["/v1/agent/check/deregister/#{check}"]
      url += check_acl_token

      ret = @conn.get concat_url(url), j
      ret.status == 200
    end

    # Marks a check as passed
    # @param check [String] The checkID to alter
    # @param note [String] An optional note
    # @return  [Boolean] Wether or not the operation succeeded
    def pass_check(check, note = '')
      set_check('pass', check, note)
    end

    # Marks a check as warning
    # @param check [String] The checkID to alter
    # @param note [String] An optional note
    # @return  [Boolean] Wether or not the operation succeeded
    def warn_check(check, note = '')
      set_check('warn', check, note)
    end

    # Marks a check as critical
    # @param check [String] The checkID to alter
    # @param note [String] An optional note
    # @return  [Boolean] Wether or not the operation succeeded
    def fail_check(check, note = '')
      set_check('fail', check, note)
    end

    # Updates a check
    # @param check [String] The checkID to alter
    # @param status [String]The new check status (passing/warning/critical)
    # @param output [String] The output of the check
    # @return  [Boolean] Wether or not the operation succeeded
    def update_check(check, status, output = '')
      url = ["/v1/agent/check/update/#{check}"]
      url += check_acl_token

      j = JSON.dump(Status: status, Output: output)
      ret = @conn.put concat_url(url), j
      ret.status == 200
    end

    # Registers a service
    # @param definition [Hash] The check definition, refer to Consul doc: https://www.consul.io/docs/agent/http/agent.html#agent_service_register
    # @return [Boolean] Wether or not the operation succeeded
    def register_service(definition)
      url = ['/v1/agent/service/register']
      url += check_acl_token

      j = JSON.dump(definition)
      ret = @conn.put concat_url(url), j
      ret.status == 200
    end

    # Deregisters a service
    # @param check [String] The serviceID to deregister
    # @return  [Boolean] Wether or not the operation succeeded
    def deregister_service(service)
      url = ["/v1/agent/service/deregister/#{service}"]
      url += check_acl_token

      ret = @conn.get concat_url(url), j
      ret.status == 200
    end

    # Passes a service into maintenance mode
    # @param service [String] Service to pass into maintenance mode
    # @param enable [Boolean] Do you enable or disable the maintenance ?
    # @param reason [String] Reason behind the maintenance mode
    # @return [Boolean] Wether or not the operation succeeded
    def service_maintenance(service, enable = true, reason = nil)
      url = ["/v1/agent/service/maintenance/#{service}"]
      url += check_acl_token
      url << use_named_parameter('enable', enable.to_s)
      url << use_named_parameter('reason', reason) if reason

      ret = @conn.put concat_url url
      ret.status == 200
    end

    private

    # Sets the state of a check, helper method
    # @param status [String] Status of the check (pass/warn/fail)
    # @param check [String] CheckID to alter
    # @param note [String] Note associated to the status of teh check
    def set_check(status, check, note = '')
      url = ["/v1/agent/check/#{status}/#{check}"]
      url += check_acl_token
      url << use_named_parameter('note', note) if note != ''

      ret = @conn.get concat_url url
      ret.status == 200
    end
  end
end
