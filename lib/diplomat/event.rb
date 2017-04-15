module Diplomat
  # Methods for interacting with the Consul event API endpoint
  class Event < Diplomat::RestClient
    include ApiOptions

    @access_methods = [:fire, :get_all, :get]

    # Send an event
    # @param name [String] the event name
    # @param value [String] the payload of the event
    # @param service [String] the target service name
    # @param node [String] the target node name
    # @param tag [String] the target tag name, must only be used with service
    # @param dc [String] the dc to target
    # @return [nil]
    def fire(name, value = nil, service = nil, node = nil, tag = nil, dc = nil)
      url = ["/v1/event/fire/#{name}"]
      url += check_acl_token
      url += use_named_parameter('service', service) if service
      url += use_named_parameter('node', node) if node
      url += use_named_parameter('tag', tag) if tag
      url += use_named_parameter('dc', dc) if dc

      @conn.put concat_url(url), value
      nil
    end

    # Get the list of events matching name
    # @param name [String] the name of the event (regex)
    # @param not_found [Symbol] behaviour if there are no events matching name;
    #   :reject with exception, :return degenerate value, or :wait for a non-empty list
    # @param found [Symbol] behaviour if there are already events matching name;
    #   :reject with exception, :return its current value, or :wait for its next value
    # @return [Array[hash]] The list of { :name, :payload } hashes
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
    # rubocop:disable MethodLength, AbcSize
    def get_all(name = nil, not_found = :reject, found = :return)
      url = ['/v1/event/list']
      url += check_acl_token
      url += use_named_parameter('name', name)
      url = concat_url url

      # Event list never returns 404 or blocks, but may return an empty list
      @raw = @conn.get url
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
          # Always set the response to 200 so we always return
          # the response body.
          @raw.status = 200
          @raw = parse_body
          return return_payload
        end
      end

      @raw = wait_for_next_event(url)
      @raw = parse_body
      return_payload
    end
    # rubocop:enable MethodLength, AbcSize

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
    # @note
    #   Whereas the consul API for events returns all past events that match
    #   name, this method allows retrieval of individual events from that
    #   sequence. However, because consul's API isn't conducive to this, we can
    #   offer first, last, next (last + 1) events, or arbitrary events in the
    #   middle, though these can only be identified relative to the preceding
    #   event. However, this is ideal for iterating through the sequence of
    #   events (while being sure that none are missed).
    # rubocop:disable MethodLength, CyclomaticComplexity, AbcSize
    def get(name = nil, token = :last, not_found = :wait, found = :return)
      url = ['/v1/event/list']
      url += check_acl_token
      url += use_named_parameter('name', name)
      @raw = @conn.get concat_url url
      body = JSON.parse(@raw.body)
      # TODO: deal with unknown symbols, invalid indices (find_index will return nil)
      idx = case token
            when :first then 0
            when :last then body.length - 1
            when :next then body.length
            else body.find_index { |e| e['ID'] == token } + 1
            end
      if idx == body.length
        case not_found
        when :reject
          raise Diplomat::EventNotFound, name
        when :return
          event_name = ''
          event_payload = ''
          event_token = :last
        when :wait
          @raw = wait_for_next_event(url)
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
          event_payload = Base64.decode64(event['Payload'])
          event_token = event['ID']
        end
      end

      {
        value: { name: event_name, payload: event_payload },
        token: event_token
      }
    end
    # rubocop:enable MethodLength, CyclomaticComplexity, AbcSize

    private

    def wait_for_next_event(url)
      index = @raw.headers['x-consul-index']
      url = [url, use_named_parameter('index', index)].join('&')
      @conn.get do |req|
        req.url concat_url url
        req.options.timeout = 86_400
      end
    end
  end
end
