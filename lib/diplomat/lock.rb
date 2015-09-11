require 'faraday'

module Diplomat
  class Lock < Diplomat::RestClient

    @access_methods = [ :acquire, :wait_to_acquire, :release ]

    # Acquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @return [Boolean] If the lock was acquired
    def acquire key, session, value=nil
      raw = @conn.put do |req|
        req.url "/v1/kv/#{key}?acquire=#{session}"
        req.body = value unless value.nil?
      end
      raw.body == 'true'
    end

    # wait to aquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @param check_interval [Integer] number of seconds to wait between retries
    # @param timeout [Integer, nil] maxiumum number of seconds to wait for a lock
    # @return [Boolean] If the lock was acquired
    def wait_to_acquire key, session, value=nil, check_interval=10, timeout=nil
      acquired = false
      begin
        Timeout.timeout(timeout) do
          while !acquired
            acquired = self.acquire key, session, value
            sleep(check_interval) if !acquired
            return true if acquired
          end
        end
      rescue Timeout::Error
        return false
      end
    end


    # Release a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @return [nil]
    def release  key, session
      raw = @conn.put do |req|
        req.url "/v1/kv/#{key}?release=#{session}"
      end
      return raw.body
    end
  end
end
