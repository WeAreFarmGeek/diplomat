require 'json'
require 'base64'
require 'faraday'

# Top level namespace ensures all required libraries are included and initializes the gem configration.
module Diplomat
  class << self
    attr_accessor :root_path
    attr_accessor :lib_path
    attr_accessor :configuration

    # Internal: Requires internal Faraday libraries.
    # @param *libs One or more relative String names to Faraday classes.
    # @return [nil]
    def require_libs(*libs)
      libs.each do |lib|
        require "#{lib_path}/#{lib}"
      end
    end

    alias require_lib require_libs
  end

  raise 'Diplomat only supports ruby >= 2.0.0' unless RUBY_VERSION.to_f >= 2.0

  self.root_path = File.expand_path __dir__
  self.lib_path = File.expand_path 'diplomat', __dir__

  require_libs 'configuration', 'rest_client', 'kv', 'datacenter', 'service',
               'members', 'node', 'nodes', 'check', 'health', 'session', 'lock',
               'error', 'event', 'acl', 'maintenance', 'query', 'agent', 'status',
               'policy', 'token', 'role'
  self.configuration ||= Diplomat::Configuration.new

  class << self
    # Build optional configuration by yielding a block to configure
    # @yield [Diplomat::Configuration]
    def configure
      self.configuration ||= Diplomat::Configuration.new
      yield(configuration)
    end

    private

    # Send all other unknown commands to Diplomat::Kv
    # @deprecated Please use Diplomat::Kv instead.
    # @param name [Symbol] Method to send to Kv
    # @param *args List of arguments to send to Kv
    # @param &block block to send to Kv
    # @return [Object]
    def method_missing(name, *args, &block)
      Diplomat::Kv.new.send(name, *args, &block) || super
    end

    # Make `respond_to_missing?` fall back to super
    #
    # @param meth_id [Symbol] the tested method
    # @oaram with_private if private methods should be tested too
    def respond_to_missing?(meth_id, with_private = false)
      access_method?(meth_id) || super
    end
  end
end
