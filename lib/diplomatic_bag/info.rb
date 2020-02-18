# frozen_string_literal: true

# Usefull usage of Diplomat lib: Info functions
module DiplomaticBag
  # rubocop:disable Metrics/AbcSize
  def self.consul_info(options = {})
    consul_self = Diplomat::Agent.self(options)
    puts 'Server: ' + consul_self['Config']['NodeName']
    puts 'Datacenter: ' + consul_self['Config']['Datacenter']
    puts 'Consul Version: ' + consul_self['Config']['Version']
    if consul_self['Stats']['consul']['leader_addr']
      puts 'Leader Address: ' + consul_self['Stats']['consul']['leader_addr']
      puts 'applied_index: ' + consul_self['Stats']['raft']['applied_index']
      puts 'commit_index: ' + consul_self['Stats']['raft']['commit_index']
    end
    members = Diplomat::Members.get(options)
    servers = members.select { |member| member['Tags']['role'] == 'consul' }.sort_by { |n| n['Name'] }
    nodes = members.select { |member| member['Tags']['role'] == 'node' }
    leader = Diplomat::Status.leader(options).split(':')[0]
    puts 'Servers Count: ' + servers.count.to_s
    puts 'Nodes Count: ' + nodes.count.to_s
    puts 'Servers:'
    servers.map do |s|
      if s['Tags']['role'] == 'consul'
        if s['Addr'] == leader
          puts '  ' + s['Name'] + ' ' + s['Addr'] + ' *Leader*'
        else
          puts '  ' + s['Name'] + ' ' + s['Addr']
        end
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
end
