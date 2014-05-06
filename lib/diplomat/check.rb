require 'base64'
require 'faraday'

module Diplomat
  class Check < Diplomat::RestClient

    # Get registered checks
    # @return [OpenStruct] all data associated with the service
    def checks
      ret = @conn.get "/v1/agent/checks"
      return OpenStruct.new JSON.parse(ret.body)
    end

    # Register a check
    # @param check_id [String] the unique id of the check
    # @param name [String] the name
    # @param notes [String] notes about the check
    # @param script [String] command to be run for check
    # @param interval [String] frequency (with units) of the check execution
    # @param ttl [String] time (with units) to mark a check down
    # @return [Integer] Status code
    def register check_id, name, notes, script, interval, ttl
      json = JSON.generate(
      {
        "ID" => check_id,
        "Name" => name,
        "Notes" => notes,
        "Script" => script,
        "Interval" => interval,
        "TTL" => ttl,
      }
      )

      ret = @conn.put do |req|
        req.url "/v1/agent/check/register"
        req.body = json
      end
      
      return ret.status
    end

    # Deregister a check
    # @param check_id [String] the unique id of the check
    # @return [Integer] Status code
    def deregister check_id
      ret = @conn.get "/v1/agent/check/deregister/#{check_id}"
      return ret.status
    end

    # Pass a check
    # @param check_id [String] the unique id of the check
    # @return [Integer] Status code
    def pass check_id
      ret = @conn.get "/v1/agent/check/pass/#{check_id}"
      return ret.status
    end

    # Warn a check
    # @param check_id [String] the unique id of the check
    # @return [Integer] Status code
    def warn check_id
      ret = @conn.get "/v1/agent/check/warn/#{check_id}"
      return ret.status
    end

    # Warn a check
    # @param check_id [String] the unique id of the check
    # @return [Integer] Status code
    def fail check_id
      ret = @conn.get "/v1/agent/check/fail/#{check_id}"
      return ret.status
    end

    # @note This is sugar, see (#get)
    def self.checks
      Diplomat::Check.new.checks
    end

    # @note This is sugar, see (#get)
    def self.register *args
      Diplomat::Check.new.register *args
    end

    # @note This is sugar, see (#get)
    def self.deregister *args
      Diplomat::Check.new.deregister *args
    end

    # @note This is sugar, see (#get)
    def self.pass *args
      Diplomat::Check.new.pass *args
    end

    # @note This is sugar, see (#get)
    def self.warn *args
      Diplomat::Check.new.warn *args
    end

    # @note This is sugar, see (#get)
    def self.fail *args
      Diplomat::Check.new.fail *args
    end

  end
end
