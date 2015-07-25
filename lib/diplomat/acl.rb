require 'base64'
require 'faraday'

module Diplomat
  class Acl < Diplomat::RestClient
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
      if raw.status == 200 and raw.body
        case found
          when :reject
            raise Diplomat::KeyAlreadyExists, key
          when :return
            @raw = raw
            return parse_body
        end
      elsif raw.status == 200 and !raw.body
        case not_found
          when :reject
            raise Diplomat::KeyNotFound, key
          when :return
            return nil
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}"
      end
    end

    # List all Acls
    # @return [List] list of [Hash] of Acls
    def list
      url = ["/v1/acl/list"]
      url += check_acl_token
      raw = @conn_no_err.get concat_url url

      if raw.status == 200
        @raw = raw
        return  parse_body
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}"
      end
    end

    # Update an Acl definition, create if not present
    # @param ID [String] the ID, mandatory
    # @param name [String] the name of the Acl
    # @param type [String] acl type
    # @option rules [String] rule definition in HCL
    # @return [String] The ID of the Affected Acl
    def update id, name=nil, type=nil, rules=nil
      value = {}
      value['Name'] = name unless name.nil?
      value['ID'] = id unless id.nil?
      value['Type'] = type unless name.nil?
      value['Rules'] = rules unless rules.nil?
      @raw = @conn.put do |req|
        url = ["/v1/acl/create"]
        url += check_acl_token
        url += use_cas(@options)
        req.url concat_url url
        req.body = value.to_json
      end
      JSON.parse(@raw.body)['ID']
    end

    # Create an Acl definition, create if not present
    # uses update without a given ID
    # @param name [String] the name of the Acl
    # @param type [String] acl type
    # @option rules [String] rule definition in HCL
    # @return [String] The ID of the Affected Acl
    def create name=nil, type=nil, rules=nil
      update(nil,name,type,rules)
    end

    # Destroy an ACl token by its id
    # @param ID [String] the Acl ID
    # @return [Bool]
    def destroy id
      @id = id
      url = ["/v1/acl/destroy/#{@id}"]
      url += check_acl_token
      @raw = @conn.put concat_url url
      @raw.body == "true"
    end

    private

    def check_acl_token
      use_named_parameter("token", Diplomat.configuration.acl_token)
    end

    def use_cas(options)
      if options then use_named_parameter("cas", options[:cas]) else [] end
    end

    def use_consistency(options)
      if options && options[:consistency] then ["#{options[:consistency]}"] else [] end
    end

  end
end
