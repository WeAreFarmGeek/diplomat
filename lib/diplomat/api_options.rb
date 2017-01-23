module Diplomat
  # Helper methods for interacting with the Consul RESTful API
  module ApiOptions
    def check_acl_token
      use_named_parameter('token', Diplomat.configuration.acl_token)
    end

    def use_cas(options)
      options ? use_named_parameter('cas', options[:cas]) : []
    end

    def use_consistency(options)
      options && options[:consistency] ? [options[:consistency].to_s] : []
    end

    # Mapping for valid key/value store transaction verbs and required parameters
    #
    # @return [Hash] valid key/store transaction verbs and required parameters
    # rubocop:disable MethodLength
    def valid_transaction_verbs
      {
        'set' => %w(Key Value),
        'cas' => %w(Key Value Index),
        'lock' => %w(Key Value Session),
        'unlock' => %w(Key Value Session),
        'get' => %w(Key),
        'get-tree' => %w(Key),
        'check-index' => %w(Key Index),
        'check-session' => %w(Key Session),
        'delete' => %w(Key),
        'delete-tree' => %w(Key),
        'delete-cas' => %w(Key Index)
      }
    end
    # rubocop:enable MethodLength

    # Key/value store transactions that require that a value be set
    #
    # @return [Array<String>] verbs that require a value be set
    def valid_value_transactions
      @valid_value_transactions ||= valid_transaction_verbs.select do |verb, requires|
        verb if requires.include? 'Value'
      end
    end
  end
end
