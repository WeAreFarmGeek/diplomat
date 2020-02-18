# frozen_string_literal: true

module Diplomat
  # Methods for interacting with the Consul event API endpoint
  class Event < Diplomat::RestClient
    @access_methods = %i[fire get_all get]

    # Send an event
    # @param name [String] the event name
    # @param value [String] the payload of the event
    # @param service [String] the target service name
    # @param node [String] the target node name
    # @param tag [String] the target tag name, must only be used with service
    # @param dc [String] the dc to target
    # @param options [Hash] options parameter hash
    # @return [nil]
    # rubocop:disable Metrics/ParameterLists
    def fire(name, value = nil, service = nil, node = nil, tag = nil, dc = nil, options = {})
      custom_params = []
      custom_params << use_named_parameter('service', service) if service
      custom_params << use_named_parameter('node', node) if node
      custom_params << use_named_parameter('tag', tag) if tag
      custom_params << use_named_parameter('dc', dc) if dc

      send_put_request(@conn, ["/v1/event/fire/#{name}"], options, value, custom_params)
      nil
    end
    # rubocop:enable Metrics/ParameterLists

    # Get the list of events matching name
    # @param name [String] the name of the event (regex)
    # @param not_found [Symbol] behaviour if there are no events matching name;
    #   :reject with exception, :return degenerate value, or :wait for a non-empty list
    # @param found [Symbol] behaviour if there are already events matching name;
    #   :reject with exception, :return its current value, or :wait for its next value
    # @return [Array[hash]] The list of { :name, :payload } hashes
    # @param options [Hash] options parameter hash
    # @note
    #   Events are sent via the gossip protocol; there is no guarantee of delivery
    #   success or order, but the local agent will store up to 256 events that do
    #   arrive. This method lists those events.
    #   It has the same semantics as Kv::get, except the value returned is a list
    #   i.e. the current value is all events up until now, the next value is the
    #   current list plus the next event to arrive.
    #   To get a specific event in the sequence, @see #get
    #   When trying to get a list of events matching a name, there are two possibilities:
    #   - The list doesn't (yet) exist / is empty
    #   - The list exists / is non-empty
    #   The combination of not_found and found behaviour gives maximum possible
    #   flexibility. For X: reject, R: return, W: wait
    #   - X X - meaningless; never return a value
    #   - X R - "normal" non-blocking get operation. Default
    #   - X W - get the next value only (must have a current value)
    #   - R X - meaningless; never return a meaningful value
    #   - R R - "safe" non-blocking, non-throwing get-or-default operation
    #   - R W - get the next value or a default
    #   - W X - get the first value only (must not have a current value)
    #   - W R - get the first or current value; always return something, but
    #           block only when necessary
    #   - W W - get the first or next value; wait until there is an update
    def get_all(name = nil, not_found = :reject, found = :return, options = {})
      # Event list never returns 404 or blocks, but may return an empty list
      @raw = send_get_request(@conn, ['/v1/event/list'], options, use_named_parameter('name', name))
      if JSON.parse(@raw.body).count.zero?
        case not_found
        when :reject
          raise Diplomat::EventNotFound, name
        when :return
          return []
        end
      else
        case found
        when :reject
          raise Diplomat::EventAlreadyExists, name
        when :return
          @raw = parse_body
          return return_payload
        end
      end

      @raw = wait_for_next_event(['/v1/event/list'], options, use_named_parameter('name', name))
      @raw = parse_body
      return_payload
    end

    # Get a specific event in the sequence matching name
    # @param name [String] the name of the event (regex)
    # @param token [String|Symbol] the ordinate of the event in the sequence;
    #   String are tokens returned by previous calls to this function
    #   Symbols are the special tokens :first, :last, and :next
    # @param not_found [Symbol] behaviour if there is no matching event;
    #   :reject with exception, :return degenerate value, or :wait for event
    # @param found [Symbol] behaviour if there is a matching event;
    #   :reject with exception, or :return its current value
    # @return [hash] A hash with keys :value and :token;
    #   :value is a further hash of the :name and :payload of the event,
    #   :token is the event's ordinate in the sequence and can be passed to future calls to get the subsequent event
    # @param options [Hash] options parameter hash
    # @note
    #   Whereas the consul API for events returns all past events that match
    #   name, this method allows retrieval of individual events from that
    #   sequence. However, because consul's API isn't conducive to this, we can
    #   offer first, last, next (last + 1) events, or arbitrary events in the
    #   middle, though these can only be identified relative to the preceding
    #   event. However, this is ideal for iterating through the sequence of
    #   events (while being sure that none are missed).
    # rubocop:disable Metrics/PerceivedComplexity
    def get(name = nil, token = :last, not_found = :wait, found = :return, options = {})
      @raw = send_get_request(@conn, ['/v1/event/list'], options, use_named_parameter('name', name))
      body = JSON.parse(@raw.body)
      # TODO: deal with unknown symbols, invalid indices (find_index will return nil)
      idx = case token
            when :first then 0
            when :last then body.length - 1
            when :next then body.length
            else body.find_index { |e| e['ID'] == token } + 1
            end
      if JSON.parse(@raw.body).count.zero? || idx == body.length
        case not_found
        when :reject
          raise Diplomat::EventNotFound, name
        when :return
          event_name = ''
          event_payload = ''
          event_token = :last
        when :wait
          @raw = wait_for_next_event(['/v1/event/list'], options, use_named_parameter('name', name))
          @raw = parse_body
          # If it's possible for two events to arrive at once,
          # this needs to #find again:
          event = @raw.last
          event_name = event['Name']
          event_payload = Base64.decode64(event['Payload'])
          event_token = event['ID']
        end
      else
        case found
        when :reject
          raise Diplomat::EventAlreadyExits, name
        when :return
          event = body[idx]
          event_name = event['Name']
          event_payload = event['Payload'].nil? ? nil : Base64.decode64(event['Payload'])
          event_token = event['ID']
        end
      end

      {
        value: { name: event_name, payload: event_payload },
        token: event_token
      }
    end
    # rubocop:enable Metrics/PerceivedComplexity

    private

    def wait_for_next_event(url, options = {}, param = nil)
      if options.nil?
        options = { timeout: 86_400 }
      else
        options[:timeout] = 86_400
      end
      index = @raw.headers['x-consul-index']
      param += use_named_parameter('index', index)
      send_get_request(@conn, url, options, param)
    end
  end
end
