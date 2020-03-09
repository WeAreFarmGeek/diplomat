# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul ACL API endpoint
  class Acl < Diplomat::RestClient
    @access_methods = %i[list info create destroy update]
    attr_reader :id, :type, :acl

    # Get Acl info by ID
    # @param id [String] ID of the Acl to get
    # @param options [Hash] options parameter hash
    # @return [Hash]
    # rubocop:disable Metrics/PerceivedComplexity
    def info(id, options = {}, not_found = :reject, found = :return)
      @id = id
      @options = options
      custom_params = []
      custom_params << use_consistency(options)

      raw = send_get_request(@conn_no_err, ["/v1/acl/info/#{id}"], options, custom_params)

      if raw.status == 200 && raw.body.chomp != 'null'
        case found
        when :reject
          raise Diplomat::AclAlreadyExists, id
        when :return
          @raw = raw
          return parse_body
        end
      elsif raw.status == 200 && raw.body.chomp == 'null'
        case not_found
        when :reject
          raise Diplomat::AclNotFound, id
        when :return
          return nil
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}: #{raw.body}"
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # List all Acls
    # @param options [Hash] options parameter hash
    # @return [List] list of [Hash] of Acls
    def list(options = {})
      @raw = send_get_request(@conn_no_err, ['/v1/acl/list'], options)
      parse_body
    end

    # Update an Acl definition, create if not present
    # @param value [Hash] Acl definition, ID field is mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] The result Acl
    def update(value, options = {})
      raise Diplomat::IdParameterRequired unless value['ID'] || value[:ID]

      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ['/v1/acl/update'], options, value, custom_params)
      parse_body
    end

    # Create an Acl definition
    # @param value [Hash] Acl definition, ID field is mandatory
    # @param options [Hash] options parameter hash
    # @return [Hash] The result Acl
    def create(value, options = {})
      custom_params = use_cas(@options)
      @raw = send_put_request(@conn, ['/v1/acl/create'], options, value, custom_params)
      parse_body
    end

    # Destroy an ACl token by its id
    # @param ID [String] the Acl ID
    # @param options [Hash] options parameter hash
    # @return [Bool] true if operation succeeded
    def destroy(id, options = {})
      @id = id
      @raw = send_put_request(@conn, ["/v1/acl/destroy/#{@id}"], options, nil)
      @raw.body.chomp == 'true'
    end
  end
end
