# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul check API endpoint
  class Check < Diplomat::RestClient
    @access_methods = %i[checks register_script register_ttl
                         deregister pass warn fail]

    # Get registered checks
    # @return [OpenStruct] all data associated with the service
    def checks(options = {})
      ret = send_get_request(@conn, ['/v1/agent/checks'], options)
      JSON.parse(ret.body)
    end

    # Register a check
    # @param check_id [String] the unique id of the check
    # @param name [String] the name
    # @param notes [String] notes about the check
    # @param args [String[]] command to be run for check
    # @param interval [String] frequency (with units) of the check execution
    # @param options [Hash] options parameter hash
    # @return [Integer] Status code
    # rubocop:disable Metrics/ParameterLists
    def register_script(check_id, name, notes, args, interval, options = {})
      unless args.is_a?(Array)
        raise(Diplomat::DeprecatedArgument, 'Script usage is deprecated, replace by an array of args')
      end

      definition = JSON.generate(
        'ID' => check_id,
        'Name' => name,
        'Notes' => notes,
        'Args' => args,
        'Interval' => interval
      )
      ret = send_put_request(@conn, ['/v1/agent/check/register'], options, definition)
      ret.status == 200
    end
    # rubocop:enable Metrics/ParameterLists

    # Register a TTL check
    # @param check_id [String] the unique id of the check
    # @param name [String] the name
    # @param notes [String] notes about the check
    # @param ttl [String] time (with units) to mark a check down
    # @param options [Hash] options parameter hash
    # @return [Boolean] Success
    def register_ttl(check_id, name, notes, ttl, options = {})
      definition = JSON.generate(
        'ID' => check_id,
        'Name' => name,
        'Notes' => notes,
        'TTL' => ttl
      )
      ret = send_put_request(@conn, ['/v1/agent/check/register'], options, definition)
      ret.status == 200
    end

    # Deregister a check
    # @param check_id [String] the unique id of the check
    # @param options [Hash] options parameter hash
    # @return [Integer] Status code
    def deregister(check_id, options = {})
      ret = send_put_request(@conn, ["/v1/agent/check/deregister/#{check_id}"], options, nil)
      ret.status == 200
    end

    # Update a TTL check
    # @param check_id [String] the unique id of the check
    # @param status [String] status of the check. Valid values are "passing", "warning", and "critical"
    # @param output [String] human-readable message will be passed through to the check's Output field
    # @param options [Hash] options parameter hash
    # @return [Integer] Status code
    def update_ttl(check_id, status, output = nil, options = {})
      definition = JSON.generate(
        'Status' => status,
        'Output' => output
      )
      ret = send_put_request(@conn, ["/v1/agent/check/update/#{check_id}"], options, definition)
      ret.status == 200
    end

    # Pass a check
    # @param check_id [String] the unique id of the check
    # @param output [String] human-readable message will be passed through to the check's Output field
    # @param options [Hash] options parameter hash
    # @return [Integer] Status code
    def pass(check_id, output = nil, options = {})
      update_ttl(check_id, 'passing', output, options)
    end

    # Warn a check
    # @param check_id [String] the unique id of the check
    # @param output [String] human-readable message will be passed through to the check's Output field
    # @param options [Hash] options parameter hash
    # @return [Integer] Status code
    def warn(check_id, output = nil, options = {})
      update_ttl(check_id, 'warning', output, options)
    end

    # Fail a check
    # @param check_id [String] the unique id of the check
    # @param output [String] human-readable message will be passed through to the check's Output field
    # @param options [Hash] options parameter hash
    # @return [Integer] Status code
    def fail(check_id, output = nil, options = {})
      update_ttl(check_id, 'critical', output, options)
    end
  end
end
