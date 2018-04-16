module Diplomat
  # Methods for interacting with the Consul query API endpoint
  class Query < Diplomat::RestClient
    include ApiOptions

    @access_methods = %i[get get_all create delete update execute explain]

    # Get a prepared query by it's key
    # @param key [String] the prepared query ID
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the prepared query
    def get(key, options = nil)
      url = ["/v1/query/#{key}"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      url << use_consistency(options) if use_consistency(options, nil)

      ret = @conn.get concat_url url
      JSON.parse(ret.body).map { |query| OpenStruct.new query }
    rescue Faraday::ClientError
      raise Diplomat::QueryNotFound
    end

    # Get all prepared queries
    # @param options [Hash] :dc Consul datacenter to query
    # @return [OpenStruct] the list of all prepared queries
    def get_all(options = nil)
      url = ['/v1/query']
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      url << use_consistency(options) if use_consistency(options, nil)
      ret = @conn.get concat_url url
      JSON.parse(ret.body).map { |query| OpenStruct.new query }
    rescue Faraday::ClientError
      raise Diplomat::PathNotFound
    end

    # Create a prepared query or prepared query template
    # @param definition [Hash] Hash containing definition of prepared query
    # @param options [Hash] :dc Consul datacenter to query
    # @return [String] the ID of the prepared query created
    def create(definition, options = nil)
      url = ['/v1/query']
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      @raw = @conn.post do |req|
        req.url concat_url url
        req.body = JSON.dump(definition)
      end

      parse_body
    rescue Faraday::ClientError
      raise Diplomat::QueryAlreadyExists
    end

    # Delete a prepared query or prepared query template
    # @param key [String] the prepared query ID
    # @param options [Hash] :dc Consul datacenter to query
    # @return [Boolean]
    def delete(key, options = nil)
      url = ["/v1/query/#{key}"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      ret = @conn.delete concat_url url

      ret.status == 200
    end

    # Update a prepared query or prepared query template
    # @param key [String] the prepared query ID
    # @param definition [Hash] Hash containing updated definition of prepared query
    # @param options [Hash] :dc Consul datacenter to query
    # @return [Boolean]
    def update(key, definition, options = nil)
      url = ["/v1/query/#{key}"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      json_definition = JSON.dump(definition)
      ret = @conn.put do |req|
        req.url concat_url url
        req.body = json_definition
      end

      ret.status == 200
    end

    # Execute a prepared query or prepared query template
    # @param key [String] the prepared query ID or name
    # @param options [Hash] prepared query execution options
    # @option dc [String] :dc Consul datacenter to query
    # @option near [String] node name to sort the resulting list in ascending order based on the
    #   estimated round trip time from that node
    # @option limit [Integer] to limit the size of the return list to the given number of results
    # @return [OpenStruct] the list of results from the prepared query or prepared query template
    # rubocop:disable PerceivedComplexity, CyclomaticComplexity, AbcSize
    def execute(key, options = nil)
      url = ["/v1/query/#{key}/execute"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]
      url << use_named_parameter('near', options[:near]) if options && options[:near]
      url << use_named_parameter('limit', options[:limit]) if options && options[:limit]

      ret = @conn.get concat_url url
      OpenStruct.new JSON.parse(ret.body)
    rescue Faraday::ClientError
      raise Diplomat::QueryNotFound
    end
    # rubocop:enable PerceivedComplexity, CyclomaticComplexity, AbcSize

    # Get the fully rendered query template
    # @param key [String] the prepared query ID or name
    # @param options [Hash] :dc Consul datacenter to query
    # @return [OpenStruct] the list of results from the prepared query or prepared query template
    def explain(key, options = nil)
      url = ["/v1/query/#{key}/explain"]
      url += check_acl_token
      url << use_named_parameter('dc', options[:dc]) if options && options[:dc]

      ret = @conn.get concat_url url
      OpenStruct.new JSON.parse(ret.body)
    rescue Faraday::ClientError
      raise Diplomat::QueryNotFound
    end
  end
end
