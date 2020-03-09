# frozen_string_literal: true

# Usefull usage of Diplomat lib: Nodes functions
module DiplomaticBag
  # Get the list of nodes having duplicate node ids
  # @param options options to query with
  # @return [Array[Object]] an array of objects with {name: node_name, status: status}
  def self.get_duplicate_node_id(options = {})
    status = {
      1 => 'Alive',
      2 => '?',
      3 => 'Left',
      4 => 'Failed'
    }
    result = []
    members = Diplomat::Members.get(options)
    grouped = members.group_by do |row|
      [row['Tags']['id']]
    end
    filtered = grouped.values.select { |a| a.size > 1 }
    filtered.each do |dup|
      instance = {}
      instance[:node_id] = dup[0]['Tags']['id']
      nodes = []
      dup.each do |inst|
        nodes << { name: inst['Name'], status: status[inst['Status']] }
      end
      instance[:nodes] = nodes
      result << instance
    end
    result
  end
end
