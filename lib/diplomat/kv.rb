require 'base64'
require 'faraday'

# Add few helpers to merge multiple keyvalues

class Array
  def to_deep_hash(value)
    self.reverse.inject(value) { |a, n| { n => a } }
  end
end

class Hash
  def deep_merge!(second)
      merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      self.merge!(second, &merger)
  end
end

module Diplomat
  class Kv < Diplomat::RestClient

    attr_reader :key, :value, :raw, :list, :results

    # Get a value by its key, potentially blocking for the first or next value
    # @param key [String] the key
    # @param options [Hash] the query params
    # @option options [String] :consistency The read consistency type
    # @param not_found [Symbol] behaviour if the key doesn't exist;
    #   :reject with exception, or :wait for it to appear
    # @param found [Symbol] behaviour if the key does exist;
    #   :reject with exception, :wait for its next value, or :return its current value
    # @return [String] The base64-decoded value associated with the key
    # @note
    #   When trying to access a key, there are two possibilites:
    #   - The key doesn't (yet) exist
    #   - The key exists. This may be its first value, there is no way to tell
    #   The combination of not_found and found behaviour gives maximum possible
    #   flexibility. For X: reject, R: return, W: wait
    #   - X X - meaningless; never return a value
    #   - X R - "normal" non-blocking get operation. Default
    #   - X W - get the next value only (must have a current value)
    #   - W X - get the first value only (must not have a current value)
    #   - W R - get the first or current value; always return something, but
    #           block only when necessary
    #   - W W - get the first or next value; wait until there is an update
    def get key, options=nil, not_found=:reject, found=:return
      @key = key
      @options = options

      url = ["/v1/kv/#{@key}"]
      url += check_acl_token unless check_acl_token.nil?
      url += use_consistency(@options) unless use_consistency(@options).nil?

      # 404s OK using this connection
      raw = @conn_no_err.get concat_url url
      if raw.status == 404
        case not_found
          when :reject
            raise Diplomat::KeyNotFound, key
          when :wait
            index = raw.headers["x-consul-index"]
        end
      elsif raw.status == 200
        case found
          when :reject
            raise Diplomat::KeyAlreadyExists, key
          when :return
            @raw = raw
            parse_body
            return return_value
          when :wait
            index = raw.headers["x-consul-index"]
        end
      else
        raise Diplomat::UnknownStatus, "status #{raw.status}"
      end

      # Wait for first/next value
      url = ["/v1/kv/#{@key}"]
      url += check_acl_token unless check_acl_token.nil?
      url += use_consistency(@options) unless use_consistency(@options).nil?
      url += ["index=#{index}"]
      @raw = @conn.get do |req|
        req.url concat_url url
        req.options.timeout = 86400
      end
      parse_body
      return_value
    end

    # Associate a value with a key
    # @param key [String] the key
    # @param value [String] the value
    # @param options [Hash] the query params
    # @option options [Integer] :cas The modify index
    # @return [Bool] Success or failure of the write (can fail in c-a-s mode)
    def put key, value, options=nil
      @options = options
      @raw = @conn.put do |req|
        url = ["/v1/kv/#{key}"]
        url += check_acl_token unless check_acl_token.nil?
        url += use_cas(@options) unless use_cas(@options).nil?
        req.url concat_url url
        req.body = value
      end
      if @raw.body == "true"
        @key   = key
        @value = value
      end
      @raw.body == "true"
    end

    # Delete a value by its key
    # @param key [String] the key
    # @return [OpenStruct]
    def delete key
      @key = key
      url = ["/v1/kv/#{@key}"]
      url += check_acl_token unless check_acl_token.nil?
      @raw = @conn.delete concat_url url
    end

    # List all keys with matching paths
    # @param key [String] the key
    # @return [Array] The list of keys with matching value
    def list_keys key,skip_directories=true
      @key = key
      url = ["/v1/kv/#{@key}?keys"]
      url += check_acl_token unless check_acl_token.nil?
      @raw = @conn.get concat_url url
      parse_list(skip_directories)
      @list 
    end

    # Get everything matching the key value, this is fast!
    # @param key [String] the key
    # @return [Hash] The list of keys with matching value
    def get_recursive key
      @key = key
      url = ["/v1/kv/#{@key}?recurse"]
      url += check_acl_token unless check_acl_token.nil?
      @raw = @conn.get concat_url url
      parse_results
      @results
    end

    # Get everything matching the key value, this is fast!
    # @param key [String] the key
    # @return [Hash] The list of keys with matching value
    def delete_recursive key
      @key = key
      url = ["/v1/kv/#{@key}?recurse"]
      url += check_acl_token unless check_acl_token.nil?
      @raw = @conn.delete concat_url url
    end

    # Put a big hash (eg. yaml file) into consul with namespace key, this is slow...
    # @param namespace [String] the namespace for values (the key)
    # @param hash [String] nested hash with values
    # @option options [Integer] :cas The modify index
    # @return [Bool] Success or failure of the write (can fail in c-a-s mode)
    def put_recursive namespace, hash, options=nil
      @options = options
      # remove trailing slash if any
      namespace.gsub(/\/+$/, '')
      key_values = nested_hash_to_key_value_hash(hash,{},namespace)

      success = true
      key_values.each do |k,v|

        # If value is nil act like key is directory
        k = "#{k}/" if v.nil?

        begin
          self.put k,v
        rescue Exception => e
          #puts "Error: #{k}=#{v}: #{e.message}"
          success = false
        end
      end
      success
    end

    # @note This is sugar, see (#get)
    def self.get *args
      Diplomat::Kv.new.get *args
    end

    # @note This is sugar, see (#put)
    def self.put *args
      Diplomat::Kv.new.put *args
    end

    # @note This is sugar, see (#delete)
    def self.delete *args
      Diplomat::Kv.new.delete *args
    end

    private

    # Parse the body, apply it to the raw attribute
    def parse_body
      @raw = JSON.parse(@raw.body)
    end

    # Parse the body of list, keep it as an array
    def parse_list(skip_directories=true)
      @list = JSON.parse(@raw.body)
      @list.delete_if { |x| x.end_with? '/' } if skip_directories
    end

    # Parse consul '?recursive' answer
    def parse_results 
      responses = JSON.parse(@raw.body)
      @results = {}
      responses.each do |item|

        # Remove the starting path from the key
        # So for example if we recursively searched everything under domains/example.com/
        # We will return just the things starting from domains/example.com/ but without the domains/example.com/ part
        item['Key'].slice!(@key)
        item['Key'].slice!('/')

        @value = item['Value']
        @value = Base64.decode64(@value) unless @value.nil?

        # Split path/to/key into array and turn it into hash
        # Point that hash into value
        hash = item['Key'].split('/').to_deep_hash(@value)
        # Merge everything into big hash
        @results.deep_merge!(hash)
      end
      @results
    end

    # Get the key from the raw output
    def return_key
      @key = @raw["Key"]
    end

    # Get the value from the raw output
    def return_value
      if @raw.count == 1
        @value = @raw.first["Value"]
        @value = Base64.decode64(@value) unless @value.nil?
      else
        @value = @raw.map do |e|
                   {
                     :key => e["Key"],
                     :value => e["Value"].nil? ? e["Value"] : Base64.decode64(e["Value"])
                   }
                 end
      end
    end

    # Turn big nested hash into nice namespaced #{k}=#{v} hashes
    def nested_hash_to_key_value_hash(source, target = {}, namespace = nil)
      prefix = "#{namespace}/" if namespace
      case source
      when Hash
        source.each do |key, value|
          nested_hash_to_key_value_hash(value, target, "#{prefix}#{key}")
        end
      when Array
        source.each_with_index do |value, index|
          nested_hash_to_key_value_hash(value, target, "#{prefix}#{index}")
        end
      else
        target[namespace] = source
      end
      target
    end

    def check_acl_token
      ["token=#{Diplomat.configuration.acl_token}"] if Diplomat.configuration.acl_token
    end

    def use_cas(options)
      ["cas=#{options[:cas]}"] if options && options[:cas]
    end

    def use_consistency(options)
      ["#{options[:consistency]}"] if options && options[:consistency]
    end
  end
end
