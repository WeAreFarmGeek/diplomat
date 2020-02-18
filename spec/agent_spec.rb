# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'base64'
# rubocop:disable
describe Diplomat::Agent do
  let(:faraday) { fake }

  context 'agent' do
    it 'self' do
      faraday.stub(:get)
             .and_return(OpenStruct.new(body: <<-JSON))
		{
		  "Config": {
			"Bootstrap": true,
			"Server": true,
			"Datacenter": "dc1",
			"DataDir": "/tmp/consul",
			"DNSRecursor": "",
			"DNSRecursors": [],
			"Domain": "consul.",
			"LogLevel": "INFO",
			"NodeName": "foobar",
			"ClientAddr": "127.0.0.1",
			"BindAddr": "0.0.0.0",
			"AdvertiseAddr": "10.1.10.12",
			"Ports": {
			  "DNS": 8600,
			  "HTTP": 8500,
			  "RPC": 8400,
			  "SerfLan": 8301,
			  "SerfWan": 8302,
			  "Server": 8300
			},
			"LeaveOnTerm": false,
			"SkipLeaveOnInt": false,
			"StatsiteAddr": "",
			"Protocol": 1,
			"EnableDebug": false,
			"VerifyIncoming": false,
			"VerifyOutgoing": false,
			"CAFile": "",
			"CertFile": "",
			"KeyFile": "",
			"StartJoin": [],
			"UiDir": "",
			"PidFile": "",
			"EnableSyslog": false,
			"RejoinAfterLeave": false
		  },
		  "Coord": {
			"Adjustment": 0,
			"Error": 1.5,
			"Vec": [0,0,0,0,0,0,0,0]
		  },
		  "Member": {
			"Name": "foobar",
			"Addr": "10.1.10.12",
			"Port": 8301,
			"Tags": {
			  "bootstrap": "1",
			  "dc": "dc1",
			  "port": "8300",
			  "role": "consul",
			  "vsn": "1",
			  "vsn_max": "1",
			  "vsn_min": "1"
			},
			"Status": 1,
			"ProtocolMin": 1,
			"ProtocolMax": 2,
			"ProtocolCur": 2,
			"DelegateMin": 2,
			"DelegateMax": 4,
			"DelegateCur": 4
		  }
		}
             JSON

      agent = Diplomat::Agent.new(faraday)

      expect(agent.self['Config']['NodeName']).to eq('foobar')
    end

    it 'checks' do
      faraday.stub(:get)
             .and_return(OpenStruct.new(body: <<-JSON))
		{
		  "service:redis": {
			"Node": "foobar",
			"CheckID": "service:redis",
			"Name": "Service 'redis' check",
			"Status": "passing",
			"Notes": "",
			"Output": "",
			"ServiceID": "redis",
			"ServiceName": "redis"
		  }
		}
             JSON

      agent = Diplomat::Agent.new(faraday)

      expect(agent.checks['service:redis']['Status']).to eq('passing')
    end

    it 'services' do
      faraday.stub(:get)
             .and_return(OpenStruct.new(body: <<-JSON))
		{
		  "redis": {
			"ID": "redis",
			"Service": "redis",
			"Tags": null,
			"Address": "",
			"Port": 8000
		  }
		}
             JSON

      agent = Diplomat::Agent.new(faraday)

      expect(agent.services['redis']['Port']).to eq(8000)
    end

    it 'members' do
      faraday.stub(:get)
             .and_return(OpenStruct.new(body: <<-JSON))
		[
		  {
			"Name": "foobar",
			"Addr": "10.1.10.12",
			"Port": 8301,
			"Tags": {
			  "bootstrap": "1",
			  "dc": "dc1",
			  "port": "8300",
			  "role": "consul"
			},
			"Status": 1,
			"ProtocolMin": 1,
			"ProtocolMax": 2,
			"ProtocolCur": 2,
			"DelegateMin": 1,
			"DelegateMax": 3,
			"DelegateCur": 3
		  }
		]
             JSON

      agent = Diplomat::Agent.new(faraday)

      expect(agent.members.size).to eq(1)
      expect(agent.members.first['Name']).to eq('foobar')
    end
  end
end
# rubocop:enable
