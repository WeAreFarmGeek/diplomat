# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul query API endpoint
  class Query < Diplomat::RestClient
    @access_methods = %i[get get_all create delete update execute explain]

    # Get a prepared query by it's key
    # @param key [String] the prepared query ID
    # @param options [Hash] :dc string for dc specific query
    # @return [OpenStruct] all data associated with the prepared query
    def get(key, options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_get_request(@conn, ["/v1/query/#{key}"], options, custom_params)
      JSON.parse(ret.body).map { |query| OpenStruct.new query }
    end

    # Get all prepared queries
    # @param options [Hash] :dc Consul datacenter to query
    # @return [OpenStruct] the list of all prepared queries
    def get_all(options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_get_request(@conn, ['/v1/query'], options, custom_params)
      JSON.parse(ret.body).map { |query| OpenStruct.new query }
    end

    # Create a prepared query or prepared query template
    # @param definition [Hash] Hash containing definition of prepared query
    # @param options [Hash] :dc Consul datacenter to query
    # @return [String] the ID of the prepared query created
    def create(definition, options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      @raw = send_post_request(@conn, ['/v1/query'], options, definition, custom_params)
      parse_body
    rescue Faraday::ClientError
      raise Diplomat::QueryAlreadyExists
    end

    # Delete a prepared query or prepared query template
    # @param key [String] the prepared query ID
    # @param options [Hash] :dc Consul datacenter to query
    # @return [Boolean]
    def delete(key, options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_delete_request(@conn, ["/v1/query/#{key}"], options, custom_params)
      ret.status == 200
    end

    # Update a prepared query or prepared query template
    # @param key [String] the prepared query ID
    # @param definition [Hash] Hash containing updated definition of prepared query
    # @param options [Hash] :dc Consul datacenter to query
    # @return [Boolean]
    def update(key, definition, options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_put_request(@conn, ["/v1/query/#{key}"], options, definition, custom_params)
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
    # rubocop:disable Metrics/PerceivedComplexity
    def execute(key, options = {})
      custom_params = []
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('near', options[:near]) if options[:near]
      custom_params << use_named_parameter('limit', options[:limit]) if options[:limit]
      ret = send_get_request(@conn, ["/v1/query/#{key}/execute"], options, custom_params)
      OpenStruct.new JSON.parse(ret.body)
    end
    # rubocop:enable Metrics/PerceivedComplexity

    # Get the fully rendered query template
    # @param key [String] the prepared query ID or name
    # @param options [Hash] :dc Consul datacenter to query
    # @return [OpenStruct] the list of results from the prepared query or prepared query template
    def explain(key, options = {})
      custom_params = options[:dc] ? use_named_parameter('dc', options[:dc]) : nil
      ret = send_get_request(@conn, ["/v1/query/#{key}/explain"], options, custom_params)
      OpenStruct.new JSON.parse(ret.body)
    end
  end
end
