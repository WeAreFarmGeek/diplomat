# Add few helpers to merge multiple keyvalues

# This is used after url eg. 'path/to/key' is splitted into array
# For example:
# ['path','to','key'].to_deep_hash
# => { 'path' => { 'to' => { 'key' => value } } }
class Array
  def to_deep_hash(value)
    self.reverse.inject(value) { |a, n| { n => a } }
  end
end

# Merges two hashes by traversing in them
# For example:
# { 'data' => { 'key' => 'value' } }.deep_merge!({ 'data' => { 'second' => 'value' } })
# => { 'data' => { 'key' => value, 'second' => 'value' } }
class Hash
  def deep_merge!(second)
      merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
      self.merge!(second, &merger)
  end
end