module Diplomat

  class << self

    attr_accessor :root_path
    attr_accessor :lib_path
    attr_accessor :url

    # Internal: Requires internal Faraday libraries.
    #
    # *libs - One or more relative String names to Faraday classes.
    #
    # Returns nothing.
    def require_libs(*libs)
      libs.each do |lib|
        require "#{lib_path}/#{lib}"
      end
    end

    alias require_lib require_libs

  end

  self.root_path = File.expand_path "..", __FILE__
  self.lib_path = File.expand_path "../diplomat", __FILE__

  # TODO: Make this configurable and overridable
  self.url = "http://localhost:3000"



  require_libs "rest_client", "kv"

end
