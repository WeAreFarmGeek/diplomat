require 'base64'
require 'faraday'

module Diplomat
  class Acl < Diplomat::RestClient

    include ApiOptions

    @access_methods = [ :list, :info, :create, :destroy, :update ]
    attr_reader :id, :type, :acl

    # Get Acl info by ID
    # @param id [String] ID of the Acl to get
    # @return [Hash]
    def info id, options=nil, not_found=:reject, found=:return
      @id = id
      @options = options

      url = ["/v1/acl/info/#{@id}"]
      url += check_acl_token
      url += use_consistency(@options)

      raw = @conn_no_err.get concat_url url
      if raw.status == 200 and raw.body != "null"
        case found
          when :reject
            raise Diplomat::AclAlreadyExists, @id
          when :return
            @raw = raw
            return parse_body
        end
      elsif raw.status == 200 and raw.body == "null"
        case not_found
          when :reject
            raise Diplomat::AclNotFound, @id
          when :return
            return nil
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}: #{raw.body}"
      end
    end

    # List all Acls
    # @return [List] list of [Hash] of Acls
    def list
      url = ["/v1/acl/list"]
      url += check_acl_token
      @raw = @conn_no_err.get concat_url url
      return parse_body
    end

    # Update an Acl definition, create if not present
    # @param value [Hash] Acl definition, ID field is mandatory
    # @return [Hash] The result Acl
    def update value
      raise Diplomat::IdParameterRequired unless value['ID']

      @raw = @conn.put do |req|
        url = ["/v1/acl/update"]
        url += check_acl_token
        url += use_cas(@options)
        req.url concat_url url
        req.body = value.to_json
      end
      return parse_body
    end

    # Create an Acl definition
    # @param value [Hash] Acl definition, ID field is mandatory
    # @return [Hash] The result Acl
    def create value
      @raw = @conn.put do |req|
        url = ["/v1/acl/create"]
        url += check_acl_token
        url += use_cas(@options)
        req.url concat_url url
        req.body = value.to_json
      end
      return parse_body
    end

    # Destroy an ACl token by its id
    # @param ID [String] the Acl ID
    # @return [Bool]
    def destroy id
      @id = id
      url = ["/v1/acl/destroy/#{@id}"]
      url += check_acl_token
      @raw = @conn.put concat_url url
      return @raw.body == "true"
    end
  end
end
