module Diplomat
  # Methods for interacting with the Consul ACL Policy API endpoint
  class Token < Diplomat::RestClient
    @access_methods = %i[list read create delete update clone self]
    attr_reader :id, :type, :acl

    # Read ACL token with the given Accessor ID
    # @param id [String] accessor ID of the ACL token to read
    # @param options [Hash] options parameter hash
    # @return [Hash] existing ACL token
    # rubocop:disable PerceivedComplexity
    def read(id, options = {}, not_found = :reject, found = :return)
      @options = options
      custom_params = []
      custom_params << use_consistency(options)

      @raw = send_get_request(@conn_no_err, ["/v1/acl/token/#{id}"], options, custom_params)

      if @raw.status == 200 && @raw.body.chomp != 'null'
        case found
        when :reject
          raise Diplomat::AclNotFound, id
        when :return
          return parse_body
        end
      elsif @raw.status == 403
        case not_found
        when :reject
          raise Diplomat::AclNotFound, id
        when :return
          return nil
        end
      else
        raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
      end
    end
    # rubocop:enable PerceivedComplexity

    # List all the ACL tokens
    # @param policy [String] filters the token list matching the specific policy ID
    # @param role [String] filters the token list matching the specific role ID
    # @param authmethod [String] the token list matching the specific named auth method
    # @param options [Hash] options parameter hash
    # @return [List] list of [Hash] of ACL tokens
    def list(policy = nil, role = nil, authmethod = nil, options = {})
      custom_params = []
      custom_params << use_named_parameter('policy', policy) if policy
      custom_params << use_named_parameter('role', policy) if role
      custom_params << use_named_parameter('authmethod', policy) if authmethod
      @raw = send_get_request(@conn_no_err, ['/v1/acl/tokens'], options, custom_params)
      raise Diplomat::AclNotFound if @raw.status == 403

      parse_body
    end

    # Update an existing ACL token
    # @param value [Hash] ACL token definition, AccessorID is mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] result ACL token
    def update(value, options = {})
      id = value[:AccessorID] || value['AccessorID']
      raise Diplomat::AccessorIdParameterRequired if id.nil?

      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ["/v1/acl/token/#{id}"], options, value, custom_params)
      if @raw.status == 200
        parse_body
      elsif @raw.status == 403
        raise Diplomat::AclNotFound, id
      elsif @raw.status == 400
        raise Diplomat::TokenMalformed, @raw.body
      else
        raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
      end
    end

    # Create a new ACL token
    # @param value [Hash] ACL token definition
    # @param options [Hash] options parameter hash
    # @return [Hash] new ACL token
    def create(value, options = {})
      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ['/v1/acl/token'], options, value, custom_params)
      return parse_body if @raw.status == 200

      raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
    end

    # Delete an existing ACL token
    # @param id [String] UUID of the ACL token to delete
    # @param options [Hash] options parameter hash
    # @return [Bool]
    def delete(id, options = {})
      anonymous_token = '00000000-0000-0000-0000-000000000002'
      raise Diplomat::NotPermitted, "status #{@raw.status}: #{@raw.body}" if id == anonymous_token

      @raw = send_delete_request(@conn, ["/v1/acl/token/#{id}"], options, nil)
      @raw.body.chomp == 'true'
    end

    # Clone an existing ACL token
    # @param value [Hash] ACL token definition, AccessorID is mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] cloned ACL token
    def clone(value, options = {})
      id = value[:AccessorID] || value['AccessorID']
      raise Diplomat::AccessorIdParameterRequired if id.nil?

      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ["/v1/acl/token/#{id}/clone"], options, value, custom_params)
      if @raw.status == 200
        parse_body
      elsif @raw.status == 403
        raise Diplomat::AclNotFound, id
      else
        raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
      end
    end

    # Returns ACL token details matching X-Consul-Token header
    # @param options [Hash] options parameter hash
    # @return [Hash] ACL token
    def self(options = {})
      custom_params = use_cas(@options)
      @raw = send_get_request(@conn, ['/v1/acl/token/self'], options, custom_params)
      if @raw.status == 200
        parse_body
      elsif @raw.status == 403
        raise Diplomat::AclNotFound, id
      end
    end
  end
end
