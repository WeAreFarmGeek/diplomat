require 'diplomatic_bag'
require_relative 'consul_mock'

describe DiplomaticBag do
  include Consul::ConsulMock

  context 'DiplomaticBag consul_info' do
    before do
      mock_consul
    end

    it 'Write to stdout' do
      expect { DiplomaticBag.consul_info }.to output.to_stdout
    end
    it 'Provide identifies the leader' do
      expect { DiplomaticBag.consul_info }.to output(/consul01 10.10.10.1 \*Leader\*/).to_stdout
      expect { DiplomaticBag.consul_info }.to output(/Leader Address: 10.10.10.1:8300/).to_stdout
    end
    it 'Count the servers' do
      expect { DiplomaticBag.consul_info }.to output(/Servers Count: 3/).to_stdout
    end
    it 'Count the nodes' do
      expect { DiplomaticBag.consul_info }.to output(/Nodes Count: 3/).to_stdout
    end
    it 'Provides datacenter name' do
      expect { DiplomaticBag.consul_info }.to output(/Datacenter: dc1/).to_stdout
    end
    it 'Provides consul version' do
      expect { DiplomaticBag.consul_info }.to output(/Consul Version: 1.5.1/).to_stdout
    end
    it 'Provides server name' do
      expect { DiplomaticBag.consul_info }.to output(/Server: consul01/).to_stdout
    end
  end

  context 'DiplomaticBag nodes' do
    before do
      mock_consul
    end

    it 'Identifies node with duplicate ids' do
      duplicates = DiplomaticBag.get_duplicate_node_id
      expect(duplicates[0][:nodes].count).to eq(2)
      expect(duplicates[0][:nodes][0][:name]).to eq('node02')
      expect(duplicates[0][:nodes][1][:name]).to eq('node03')
      expect(duplicates[0][:node_id]).to eq('7335867c-ca76-81d9-ef8b-f0e3e30b8102')
    end
  end

  context 'DiplomaticBag services' do
    before do
      mock_consul
    end

    it 'Provides all services status' do
      services = DiplomaticBag.get_all_services_status
      expect(services.count).to eq(4)
      expect(services['service01']).to eq('passing' => 1)
      expect(services['service02']).to eq('passing' => 1)
      expect(services['service03']).to eq('passing' => 1, 'critical' => 1)
      expect(services['service04']).to eq('critical' => 1)
    end

    it 'Provides service check status for a specific service' do
      services = DiplomaticBag.get_services_info('service03')
      expect(services[0]['service03'].count).to eq(2)
      expect(services[0]['service03']['node03']['Checks']["Service 'service03' check"][:status]).to eq('passing')
      expect(services[0]['service03']['node01']['Checks']["Service 'service03' check"][:status]).to eq('critical')
    end

    it 'Provides service check status for a service with wildcard' do
      services = DiplomaticBag.get_services_info('service*')
      expect(services.count).to eq(4)
      expect(services[0]['service01']['node01']['Checks']["Service 'service01' check"][:status]).to eq('passing')
      expect(services[1]['service02']['node02']['Checks']["Service 'service02' check"][:status]).to eq('passing')
      expect(services[2]['service03']['node03']['Checks']["Service 'service03' check"][:status]).to eq('passing')
      expect(services[2]['service03']['node01']['Checks']["Service 'service03' check"][:status]).to eq('critical')
      expect(services[3]['service04']['node03']['Checks']["Service 'service04' check"][:status]).to eq('critical')
    end

    it 'It returns the list of services that matches the name requested' do
      services = DiplomaticBag.get_services_list('service03')
      expect(services.count).to eq(1)
      services = DiplomaticBag.get_services_list('service*')
      expect(services.count).to eq(4)
    end
  end

  context 'DiplomaticBag service' do
    before do
      mock_consul
    end

    it 'Provides nodes that runs a specific service' do
      service = DiplomaticBag.get_service_info('service03')
      expect(service['service03'].count).to eq(2)
      expect(service['service03']['node03']['Checks']["Service 'service03' check"][:status]).to eq('passing')
      expect(service['service03']['node01']['Checks']["Service 'service03' check"][:status]).to eq('critical')
    end
  end

  context 'DiplomaticBag datacenter' do
    before do
      mock_consul
    end

    it 'Provide the right amount of datacenters' do
      dcs = DiplomaticBag.get_datacenters_list(['DC1'])
      expect(dcs.count).to eq(1)
      dcs = DiplomaticBag.get_datacenters_list(%w[D C])
      expect(dcs.count).to eq(3)
    end
  end
end
