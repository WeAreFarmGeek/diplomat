# frozen_string_literal: true

module Diplomat
  # Methods for configuring Diplomat
  class Configuration
    attr_reader :middleware
    attr_accessor :url, :acl_token, :options

    # Get the most appropriate consul agent value from env
    # Parse the environment variable `CONSUL_HTTP_ADDR` and prefixes it with http:// if needed
    # Return default http://localhost:8500 if not found
    def self.parse_consul_addr
      ret = ENV['CONSUL_HTTP_ADDR'] || 'http://localhost:8500'
      ret = "http://#{ret}" unless ret.start_with?('http://', 'https://')
      ret
    end

    # Override defaults for configuration
    # @param url [String] consul's connection URL
    # @param acl_token [String] a connection token used when making requests to consul
    # @param options [Hash] extra options to configure Faraday::Connection
    def initialize(url = Configuration.parse_consul_addr, acl_token = ENV['CONSUL_HTTP_TOKEN'], options = {})
      @middleware = []
      @url = url
      @acl_token = acl_token
      @options = options
    end

    # Define a middleware for Faraday
    # @param middleware [Class] Faraday Middleware class
    # @return [Array] Array of Faraday Middlewares
    def middleware=(middleware)
      if middleware.is_a? Array
        @middleware = middleware
        return
      end
      @middleware = [middleware]
    end
  end
end
