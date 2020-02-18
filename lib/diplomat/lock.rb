# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul lock API endpoint
  class Lock < Diplomat::RestClient
    @access_methods = %i[acquire wait_to_acquire release]

    # Acquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @param options [Hash] options parameter hash
    # @return [Boolean] If the lock was acquired
    def acquire(key, session, value = nil, options = {})
      key = normalize_key_for_uri(key)
      custom_params = []
      custom_params << use_named_parameter('acquire', session)
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('flags', options[:flags]) if options && options[:flags]
      data = value unless value.nil?
      raw = send_put_request(@conn, ["/v1/kv/#{key}"], options, data, custom_params)
      raw.body.chomp == 'true'
    end

    # wait to aquire a lock
    # @param key [String] the key
    # @param session [String] the session, generated from Diplomat::Session.create
    # @param value [String] the value for the key
    # @param check_interval [Integer] number of seconds to wait between retries
    # @param options [Hash] options parameter hash
    # @return [Boolean] If the lock was acquired
    def wait_to_acquire(key, session, value = nil, check_interval = 10, options = {})
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
    # rubocop:disable Metrics/AbcSize
    def release(key, session, options = {})
      key = normalize_key_for_uri(key)
      custom_params = []
      custom_params << use_named_parameter('release', session)
      custom_params << use_named_parameter('dc', options[:dc]) if options[:dc]
      custom_params << use_named_parameter('flags', options[:flags]) if options && options[:flags]
      raw = send_put_request(@conn, ["/v1/kv/#{key}"], options, nil, custom_params)
      raw.body
    end
    # rubocop:enable Metrics/AbcSize
  end
end
