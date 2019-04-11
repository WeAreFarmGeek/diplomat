#!/usr/bin/env ruby
# rubocop:disable all

require 'diplomatic_bag'
require 'optparse'

def syntax
  printf "USAGE: #{$PROGRAM_NAME} [[action]] [[options]]\n\n" \
          "\t#{$PROGRAM_NAME} services list [options]\n" \
          "\t#{$PROGRAM_NAME} service status <service-name> [options]\n" \
          "\t#{$PROGRAM_NAME} info [options]\n" \
          "\t#{$PROGRAM_NAME} nodes list-duplicate-id [options]\n\n" \
          "Options:\n" \
          "\t-a, --http-addr\t\tThe `address` and port of the Consul HTTP agent\n" \
          "\t-d, --datacenter\tName of the datacenter to query\n" \
          "\t-f, --format\t\tOutput format (json|text)\n" \
          "\t-t, --token\t\tACL token to use in the request\n"
  exit 0
end

def launch_query(arguments, options)
  case arguments[0]
  when 'services'
    if arguments[1] == 'list'
      DiplomaticBag.get_all_services_status(options)
    else
      syntax
      exit 0
    end
  when 'service'
    if arguments[1] == 'status'
      DiplomaticBag.get_services_info(arguments[2], options)
    else
      syntax
      exit 0
    end
  when 'info'
    DiplomaticBag.consul_info(options)
  when 'nodes'
    if arguments[1] == 'list-duplicate-id'
      DiplomaticBag.get_duplicate_node_id(options)
    else
      syntax
      exit 0
    end
  else
    syntax
    exit 0
  end
end

def parse_as_text(input, indent)
  case input
  when Array
    input.each do |v|
      parse_as_text(v, indent)
    end
  when Hash
    input.each do |k, v|
      print "#{indent}#{k}:\n"
      parse_as_text(v, indent+'  ')
    end
  else
    print "#{indent}#{input}\n"
  end
end

options = {http_addr: ENV['CONSUL_HTTP_ADDR'] || 'localhost:8500'}
params = {}
output = {}

OptionParser.new do |opts|
  opts.banner = "USAGE: #{$PROGRAM_NAME} -a [[action]] [[options]]"

  opts.on('-h', '--help', 'Show help') do
    syntax
  end

  opts.on("-a", "--http-addr [CONSUL_URL]", "The `address` and port of the Consul HTTP agent") do |server|
    options[:http_addr] = server
  end

  opts.on("-d", "--datacenter [DATACENTER]", "Name of the datacenter to query (services option)") do |dc|
    params[:dcs] = dc
  end

  opts.on("-f", "--format TYPE", [:json, :txt], "Output format") do |format|
    params[:format] = format
  end

  opts.on("-t", "--token [TOKEN]", "ACL token to use in the request") do |token|
    options[:token] = token
  end
end.parse!

options[:http_addr] = "http://#{options[:http_addr]}" unless options[:http_addr].start_with? 'http'

if params[:dcs]
  dcs = DiplomaticBag.get_datacenters_list(params[:dcs].split(','), options)
  dcs.each do |dc|
    options[:dc] = dc
    output[dc] = launch_query(ARGV, options)
  end
else
  output = launch_query(ARGV, options)
end
case params[:format]
when :json
  puts JSON.pretty_generate(output) unless output == {}
else
  parse_as_text(output, '') unless output == {}
end

# rubocop:enable all