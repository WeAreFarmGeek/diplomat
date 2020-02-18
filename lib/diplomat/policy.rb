# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul ACL Policy API endpoint
  class Policy < Diplomat::RestClient
    @access_methods = %i[list read create delete update]
    attr_reader :id, :type, :acl

    # Read ACL policy with the given UUID
    # @param id [String] UUID of the ACL policy to read
    # @param options [Hash] options parameter hash
    # @return [Hash] existing ACL policy
    # rubocop:disable Metrics/PerceivedComplexity
    def read(id, options = {}, not_found = :reject, found = :return)
      @options = options
      custom_params = []
      custom_params << use_consistency(options)

      @raw = send_get_request(@conn_no_err, ["/v1/acl/policy/#{id}"], options, custom_params)

      if @raw.status == 200 && @raw.body.chomp != 'null'
        case found
        when :reject
          raise Diplomat::PolicyNotFound, id
        when :return
          return parse_body
        end
      elsif @raw.status == 404
        case not_found
        when :reject
          raise Diplomat::PolicyNotFound, id
        when :return
          return nil
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
    # rubocop:enable Metrics/PerceivedComplexity

    # List all the ACL policies
    # @param options [Hash] options parameter hash
    # @return [List] list of [Hash] of ACL policies
    def list(options = {})
      @raw = send_get_request(@conn_no_err, ['/v1/acl/policies'], options)
      raise Diplomat::AclNotFound if @raw.status == 403

      parse_body
    end

    # Update an existing ACL policy
    # @param value [Hash] ACL policy definition, ID and Name fields are mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] result ACL policy
    def update(value, options = {})
      id = value[:ID] || value['ID']
      raise Diplomat::IdParameterRequired if id.nil?

      policy_name = value[:Name] || value['Name']
      raise Diplomat::NameParameterRequired if policy_name.nil?

      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ["/v1/acl/policy/#{id}"], options, value, custom_params)
      if @raw.status == 200
        parse_body
      elsif @raw.status == 400
        raise Diplomat::PolicyMalformed, @raw.body
      else
        raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
      end
    end

    # Create a new ACL policy
    # @param value [Hash] ACL policy definition, Name field is mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] new ACL policy
    def create(value, options = {})
      blacklist = ['ID', 'iD', 'Id', :ID, :iD, :Id] & value.keys
      raise Diplomat::PolicyMalformed, 'ID should not be specified' unless blacklist.empty?

      id = value[:Name] || value['Name']
      raise Diplomat::NameParameterRequired if id.nil?

      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ['/v1/acl/policy'], options, value, custom_params)

      # rubocop:disable Style/GuardClause
      if @raw.status == 200
        return parse_body
      elsif @raw.status == 500 && @raw.body.chomp.include?('already exists')
        raise Diplomat::PolicyAlreadyExists, @raw.body
      else
        raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
      end
    end
    # rubocop:enable Style/GuardClause

    # Delete an ACL policy by its UUID
    # @param id [String] UUID of the ACL policy to delete
    # @param options [Hash] options parameter hash
    # @return [Bool]
    def delete(id, options = {})
      @raw = send_delete_request(@conn, ["/v1/acl/policy/#{id}"], options, nil)
      @raw.body.chomp == 'true'
    end
  end
end
