require 'faraday'

module Diplomat
  class Lock < Diplomat::RestClient

    include ApiOptions

    @access_methods = [ :acquire, :wait_to_acquire, :release ]

    # Acquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @return [Boolean] If the lock was acquired
    def acquire key, session, value=nil
      raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += use_named_parameter('acquire', session)
        url += check_acl_token

        req.url concat_url url
        req.body = value unless value.nil?
      end
      raw.body == 'true'
    end

    # wait to aquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @param check_interval [Integer] number of seconds to wait between retries
    # @return [Boolean] If the lock was acquired
    def wait_to_acquire key, session, value=nil, check_interval=10
      acquired = false
      while !acquired
        acquired = self.acquire key, session, value
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
        url = ["/v1/kv/#{key}"]
        url += use_named_parameter('release', session)
        url += check_acl_token

        req.url concat_url url
      end
      return raw.body
    end
  end
end
