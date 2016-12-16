require 'base64'
require 'faraday'

module Diplomat
  class PreparedQuery < Diplomat::RestClient

    include ApiOptions

    @access_methods = [ :list, :info, :create, :destroy, :update ]
    attr_reader :name, :pquery

    # Get Prepared Query info by name
    # @param name [String] Name of the Query to get
    # @return [Hash]
    def info name, not_found=:reject, found=:return
      @name = name

      # As long as creating a query is not doable by specifying an ID,
      # but that one is used is subsequent calls (update, delete), we
      # rely on list to search by Name
      result = self.list.select { |pquery| pquery['Name'] == @name }

      if result.nil? || result.empty?
        case not_found
          when :reject
            raise Diplomat::PreparedQueryNotFound, name
          when :return
            return nil
        end
      else
        case found
          when :reject
            raise Diplomat::PreparedQueryAlreadyExists, name
          when :return
            return result.first
        end
      end
    end

    # List all Prepared Queries
    # @return [List] list of [Hash] of Prepared Queries
    def list
      url = ["/v1/query"]
      url += check_acl_token
      @raw = @conn_no_err.get concat_url url
      return parse_body
    end

    # Update a Prepared Query definition, create if not present
    # @param pquery [Hash] Prepared Query definition
    # @return [Hash] The result Prepared Query
    def update name, pquery
      @name = name

      old_query = info(name)
      id = old_query['ID']

      # ID is added to match the API spec
      pquery['ID'] = id

      @raw = @conn.put do |req|
        url = ["/v1/query/#{id}"]
        url += check_acl_token
        req.url concat_url url
        req.body = pquery.to_json
      end
      return @raw.status == 200
    end

    # Create a Prepared Query
    # @param pquery [Hash] Prepared Query definition
    # @return [Hash] The result Prepared Query
    def create pquery
      @raw = @conn.post do |req|
        url = ["/v1/query"]
        url += check_acl_token
        req.url concat_url url
        req.body = pquery.to_json
      end
      doc = parse_body
      @id = doc['ID']
      return doc
    end

    # Destroy a Prepared Query by its id
    # @param Name [String] the Prepared Query Name
    # @return [Bool]
    def destroy name
      @name = name

      old_query = info(name)
      id = old_query['ID']

      @raw = @conn.delete do |req|
        url = ["/v1/query/#{@id}"]
        url += check_acl_token
        req.url concat_url url
      end
      return @raw.status == 200
    end
  end
end
