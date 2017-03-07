module Diplomat
  # Methods for interacting with the Consul lock API endpoint
  class Lock < Diplomat::RestClient
    include ApiOptions

    @access_methods = [:acquire, :wait_to_acquire, :release]

    # Acquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @param options [Hash] :dc string for dc specific query
    # @return [Boolean] If the lock was acquired
    # rubocop:disable AbcSize
    def acquire(key, session, value = nil, options = nil)
      raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += use_named_parameter('acquire', session)
        url += check_acl_token
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
        req.body = value unless value.nil?
      end
      raw.body.chomp == 'true'
    end

    # wait to aquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @param check_interval [Integer] number of seconds to wait between retries
    # @param options [Hash] :dc string for dc specific query
    # @return [Boolean] If the lock was acquired
    def wait_to_acquire(key, session, value = nil, check_interval = 10, options = nil)
      acquired = false
      until acquired
        acquired = acquire(key, session, value, options)
        sleep(check_interval) unless acquired
        return true if acquired
      end
    end

    # Release a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param options [Hash] :dc string for dc specific query
    # @return [nil]
    def release(key, session, options = nil)
      raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += use_named_parameter('release', session)
        url += check_acl_token
        url += use_named_parameter('dc', options[:dc]) if options && options[:dc]

        req.url concat_url url
      end
      raw.body
    end
  end
end
