module Diplomat
  # Methods for interacting with the Consul ACL Role API endpoint
  class Role < Diplomat::RestClient
    @access_methods = %i[list read create delete update]
    attr_reader :id, :type, :acl

    # Read ACL role with the given UUID or name
    # @param id [String] UUID or name of the ACL role to read
    # @param options [Hash] options parameter hash
    # @return [Hash] existing ACL role
    # rubocop:disable PerceivedComplexity
    def read(id, options = {}, not_found = :reject, found = :return)
      endpoint = if id =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
                   "/v1/acl/role/#{id}"
                 else
                   "/v1/acl/role/name/#{id}"
                 end
      @options = options
      custom_params = []
      custom_params << use_consistency(options)

      @raw = send_get_request(@conn_no_err, [endpoint], options, custom_params)

      if @raw.status == 200 && @raw.body.chomp != 'null'
        case found
        when :reject
          raise Diplomat::RoleNotFound, id
        when :return
          return parse_body
        end
      elsif @raw.status == 404
        case not_found
        when :reject
          raise Diplomat::RoleNotFound, id
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
    # rubocop:enable PerceivedComplexity

    # List all the ACL roles
    # @param options [Hash] options parameter hash
    # @return [List] list of [Hash] of ACL roles
    def list(options = {})
      @raw = send_get_request(@conn_no_err, ['/v1/acl/roles'], options)
      raise Diplomat::AclNotFound if @raw.status == 403

      parse_body
    end

    # Update an existing ACL role
    # @param value [Hash] ACL role definition, ID and Name fields are mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] result ACL role
    def update(value, options = {})
      id = value[:ID] || value['ID']
      raise Diplomat::IdParameterRequired if id.nil?

      role_name = value[:Name] || value['Name']
      raise Diplomat::NameParameterRequired if role_name.nil?

      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ["/v1/acl/role/#{id}"], options, value, custom_params)
      if @raw.status == 200
        parse_body
      elsif @raw.status == 400
        raise Diplomat::RoleMalformed, @raw.body
      else
        raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
      end
    end

    # Create a new ACL role
    # @param value [Hash] ACL role definition, Name field is mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] new ACL role
    def create(value, options = {})
      blacklist = ['ID', 'iD', 'Id', :ID, :iD, :Id] & value.keys
      raise Diplomat::RoleMalformed, 'ID should not be specified' unless blacklist.empty?

      id = value[:Name] || value['Name']
      raise Diplomat::NameParameterRequired if id.nil?

      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ['/v1/acl/role'], options, value, custom_params)

      # rubocop:disable GuardClause
      if @raw.status == 200
        return parse_body
      elsif @raw.status == 500 && @raw.body.chomp.include?('already exists')
        raise Diplomat::RoleAlreadyExists, @raw.body
      else
        raise Diplomat::UnknownStatus, "status #{@raw.status}: #{@raw.body}"
      end
    end
    # rubocop:enable GuardClause

    # Delete an ACL role by its UUID
    # @param id [String] UUID of the ACL role to delete
    # @param options [Hash] options parameter hash
    # @return [Bool]
    def delete(id, options = {})
      @raw = send_delete_request(@conn, ["/v1/acl/role/#{id}"], options, nil)
      @raw.body.chomp == 'true'
    end
  end
end
