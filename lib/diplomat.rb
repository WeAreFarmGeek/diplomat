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

  self.root_path = File.expand_path "..", __FILE__
  self.lib_path = File.expand_path "../diplomat", __FILE__

  require_libs "configuration", "rest_client", "kv", "datacenter", "service", "members", "check", "health", "session", "lock", "error", "event"
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
      Diplomat::Kv.new.send(name, *args, &block)
    end
  end
end