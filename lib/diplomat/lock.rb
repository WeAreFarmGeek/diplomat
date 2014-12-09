require 'faraday'

module Diplomat
  class Lock < Diplomat::RestClient

    # Acquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @return [Boolean] If the lock was acquired
    def acquire key, session
      raw = @conn.put do |req|
        req.url "/v1/kv/#{key}?acquire=#{session}"
      end
      return true if raw.body == 'true'
      return false

    end

    # wait to aquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param check_interval [Integer] number of seconds to wait between retries
    # @return [Boolean] If the lock was acquired
    def wait_to_acquire key, session, check_interval=10
      acquired = false
      while !acquired
        acquired = self.acquire key, session
        sleep(check_interval) if !acquired
        return true if acquired
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

    # @note This is sugar, see (#acquire)
    def self.acquire *args
      Diplomat::Lock.new.acquire *args
    end

    # @note This is sugar, see (#wait_to_acquire)
    def self.wait_to_acquire *args
      Diplomat::Lock.new.wait_to_acquire *args
    end

    # @note This is sugar, see (#release)
    def self.release *args
      Diplomat::Lock.new.release *args
    end
  end
end
