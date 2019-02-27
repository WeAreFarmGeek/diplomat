require 'spec_helper'

describe Diplomat::Node do
  context 'nodes' do
    let(:node_definition) do
      {
        'Node' => 'foobar',
        'Address' => '192.168.10.10'
      }
    end

    describe '#register' do
      let(:path) { 'http://localhost:8500/v1/catalog/register' }

      it 'registers a node' do
        json = JSON.generate(node_definition)

        stub_request(:put, path)
          .with(body: json).and_return(OpenStruct.new(body: '', status: 200))

        node = Diplomat::Node.new

        n = node.register(node_definition)
        expect(n).to eq(true)
      end
    end

    describe '#deregister' do
      let(:path) { 'http://localhost:8500/v1/catalog/deregister' }

      it 'de-registers a node' do
        json = JSON.generate(node_definition)

        stub_request(:put, path)
          .with(body: json).and_return(OpenStruct.new(body: '', status: 200))

        node = Diplomat::Node.new

        n = node.deregister(node_definition)
        expect(n).to eq(true)
      end
    end
  end

  context 'services' do
    let(:key) { 'foobar' }
    let(:key_url) { "http://localhost:8500/v1/catalog/node/#{key}" }
    let(:all_url) { 'http://localhost:8500/v1/catalog/nodes' }
    let(:body_all) do
      [
        {
          'Address' => '10.1.10.12',
          'Node' => 'foo'
        },
        {
          'Address' => '10.1.10.13',
          'Node' => 'bar'
        }
      ]
    end
    let(:body) do
      {
        'Node' => {
          'Node' => 'foobar',
          'Address' => '10.1.10.12'
        },
        'Services' => {
          'consul' => {
            'ID' => 'consul',
            'Service' => 'consul',
            'Tags' => nil,
            'Port' => 8300
          },
          'redis' => {
            'ID' => 'redis',
            'Service' => 'redis',
            'Tags' => [
              'v1'
            ],
            'Port' => 8000
          }
        }
      }
    end
    let(:all_with_dc_url) { 'http://localhost:8500/v1/catalog/nodes?dc=dc1' }
    let(:body_all_with_dc) do
      [
        {
          'Address' => '10.1.10.14',
          'Node' => 'foo'
        }
      ]
    end

    describe 'GET ALL' do
      it 'lists all the nodes' do
        json = JSON.generate(body_all)

        stub_request(:get, all_url).and_return(OpenStruct.new(body: json))

        node = Diplomat::Node.new
        expect(node.get_all.size).to eq(2)
      end

      it 'lists all the nodes' do
        json = JSON.generate(body_all_with_dc)

        stub_request(:get, all_with_dc_url).and_return(OpenStruct.new(body: json))

        node = Diplomat::Node.new
        expect(node.get_all(dc: 'dc1').size).to eq(1)
      end
    end

    describe 'GET' do
      let(:cn) do
        json = JSON.generate(body)
        Diplomat.configuration.acl_token = nil
        stub_request(:get, key_url).and_return(OpenStruct.new(body: json))
        node = Diplomat::Node.new
        node.get('foobar')
      end

      it 'gets a node' do
        expect(cn['Node'].length).to eq(2)
      end

      it 'returns an OpenStruct' do
        expect(cn).to be_a_kind_of(OpenStruct)
      end
    end
  end

  context 'acl' do
    let(:node_name) { 'foobar' }
    let(:acl_token) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f1' }

    describe 'GET' do
      # Verify that URL passed to Faraday is without token
      it 'token empty' do
        stub_request(:get, "http://localhost:8500/v1/catalog/node/#{node_name}").and_return(OpenStruct.new(body: '{}'))

        Diplomat.configuration.acl_token = nil
        node = Diplomat::Node.new

        node.get(node_name)
      end

      # Verify that URL passed to Faraday has token from Diplomat.configuration.acl_token
      it 'token specified' do
        stub_request(:get, "http://localhost:8500/v1/catalog/node/#{node_name}")
          .with(headers: { 'X-Consul-Token' => acl_token }).and_return(OpenStruct.new(body: '{}'))

        Diplomat.configuration.acl_token = acl_token
        node = Diplomat::Node.new

        node.get(node_name)
      end
    end
  end
end
