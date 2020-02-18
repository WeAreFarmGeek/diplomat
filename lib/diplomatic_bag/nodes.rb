# frozen_string_literal: true

# Usefull usage of Diplomat lib: Nodes functions
module DiplomaticBag
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
