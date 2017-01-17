require 'spec_helper'

describe Diplomat::Nodes do
  let(:faraday) { fake }
  let(:datacenter) { 'us-west2' }
  let(:datacenter_body_all) do
    [
      {
        'Address' => '10.1.10.12',
        'Node' => 'foo',
        'Datacenter' => 'us-west2'
      }
    ]
  end
  let(:all_datacenter_url) { "/v1/catalog/nodes?dc=#{datacenter}" }

  context 'nodes' do
    it 'GET' do
      json = JSON.generate(
        [
          {
            'Node' => 'baz',
            'Address' => '10.1.10.11'
          },
          {
            'Node' => 'foobar',
            'Address' => '10.1.10.12'
          }
        ]
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))

      nodes = Diplomat::Nodes.new(faraday)

      expect(nodes.get.first['Node']).to eq('baz')
      expect(nodes.get.first['Address']).to eq('10.1.10.11')
    end

    it 'GET ALL' do
      json = JSON.generate(datacenter_body_all)
      faraday.stub(:get).with(all_datacenter_url).and_return(OpenStruct.new(body: json))

      nodes = Diplomat::Nodes.new(faraday)
      options = { dc: 'us-west2' }
      expect(nodes.get_all(options).size).to eq(1)
    end
  end
end
