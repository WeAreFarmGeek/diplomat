require 'spec_helper'

describe Diplomat::Agent do
  let(:faraday) { fake }

  context 'Operations on checks' do
    let(:all_checks) do
      {
        ping_check: {
          ID: 'ping_check',
          Name: 'ping_check',
          Script: 'ping -c1 github.com',
          Interval: '10s',
          TTL: '20s'
        },
        cheesy_check: {
          ID: 'cheesy_check',
          Name: 'cheesy_check',
          Script: 'echo mimolette',
          Interval: '10s',
          TTL: '20s'
        }
      }
    end

    let(:check_body) do
      {
        ID: 'ping_check',
        Name: 'ping_check',
        Script: 'ping -c1 github.com',
        Interval: '10s',
        TTL: '20s'
      }
    end

    it 'list registered checks' do
      json = JSON.generate(all_checks)
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.checks['ping_check']['ID']).to eq('ping_check')
      expect(agent.checks['ping_check']['Name']).to eq('ping_check')
      expect(agent.checks.is_a?(Hash)).to eq(true)
      expect(agent.checks.length).to eq(2)
    end

    it 'register a check' do
      faraday.stub(:put).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.register_check(check_body)).to eq(true)
    end

    it 'deregister a check' do
      faraday.stub(:get).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.deregister_check('some_check')).to eq(true)
    end

    it 'pass a check' do
      faraday.stub(:get).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.pass_check('some_check')).to eq(true)
    end

    it 'fail a check' do
      faraday.stub(:get).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.fail_check('some_check')).to eq(true)
    end

    it 'warn a check' do
      faraday.stub(:get).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.warn_check('some_check')).to eq(true)
    end

    it 'update a check' do
      faraday.stub(:put).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.update_check('some_check', 'warning', 'this is output')).to eq(true)
    end
  end

  context 'Operations on services' do
    let(:all_services) do
      {
        redis1: {
          ID: 'redis1',
          Name: 'redis1'
        },
        redis2: {
          ID: 'redis2',
          Name: 'redis2'
        }
      }
    end

    let(:service_body) do
      {
        ID: 'redis1',
        Name: 'redis1'
      }
    end

    it 'list registered services' do
      json = JSON.generate(all_services)
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.services['redis1']['ID']).to eq('redis1')
      expect(agent.services['redis2']['Name']).to eq('redis2')
      expect(agent.services.is_a?(Hash)).to eq(true)
      expect(agent.services.length).to eq(2)
    end

    it 'register a service' do
      faraday.stub(:put).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.register_service(service_body)).to eq(true)
    end

    it 'deregister a service' do
      faraday.stub(:get).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.deregister_service('some_service')).to eq(true)
    end

    it 'put some service in maintenance mode' do
      faraday.stub(:put).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.service_maintenance('some_service', true, 'this is a reason')).to eq(true)
    end
  end

  context 'Operations on members and local agent' do
    let(:all_members_body) do
      [
        {
          Name: 'somehost',
          Addr: '42.42.42.42',
          Port: 8301
        },
        {
          Name: 'somehost2',
          Addr: '42.42.42.43',
          Port: 8301
        }
      ]
    end

    let(:agent_config) do
      {
        Config: {
          'DevMode' => false
        }
      }
    end

    it 'list cluster members' do
      json = JSON.generate(all_members_body)
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.members.first['Name']).to eq('somehost')
      expect(agent.members.is_a?(Array)).to eq(true)
      expect(agent.members.length).to eq(2)
    end

    it 'reload local agent' do
      faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: 'true'))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.reload).to eq(true)
    end

    it 'make local agent leave the cluster' do
      faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: 'true'))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.leave).to eq(true)
    end

    it 'make any agent leave the cluster' do
      faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: 'true'))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.force_leave('some_host')).to eq(true)
    end

    it 'make local agent join the cluster' do
      faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: 'true'))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.join('some_host')).to eq(true)
    end

    it 'dump local agent configuratuion' do
      json = JSON.generate(agent_config)
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.self).to eq(OpenStruct.new(agent_config))
    end

    it 'put local agent in maintenance mode' do
      faraday.stub(:put).and_return(OpenStruct.new(body: 'true', status: 200))
      agent = Diplomat::Agent.new(faraday)

      expect(agent.maintenance(true, 'this is a reason')).to eq(true)
    end
  end
end
