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
      response = raw(:acquire, key, session: session, value: value)
      response == 'true'
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
    def release key, session
      raw(:release, key, session: session)
    end

    # Interact directly with KV endpoint
    # @param action [Symbol] the locking action to take (:acquire or :release)
    # @param key [String] the key to lock
    # @param options [Hash] KV endpoint options
    # @option options [String] :session the session, generated from Diplomat::Session.create
    # @option options [String] :dc the target DC
    # @option options [String] :value the value to set on the key
    # @return [String] The consul KV response body. Can be nil
    def raw action, key, options={}
      raise Diplomat::IdParameterRequired unless options[:session]
      raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += use_named_parameter(action.to_s, options[:session])
        url += use_named_parameter('dc', options[:dc])
        url += check_acl_token

        req.url concat_url url
        req.body = options[:value] unless options[:value].nil?
      end
      return raw.body
    end
  end
end
