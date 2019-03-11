require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Datacenter do
  context 'datacenters' do
    let(:key_url) { 'http://localhost:8500/v1/catalog/datacenters' }
    let(:body) { %w[dc1 dc2] }
    let(:headers) do
      {
        'x-consul-index' => '8',
        'x-consul-knownleader' => 'true',
        'x-consul-lastcontact' => '0'
      }
    end

    describe 'GET' do
      it 'returns dcs' do
        json = JSON.generate(body)

        stub_request(:get, key_url).to_return(OpenStruct.new(body: json))

        datacenters = Diplomat::Datacenter

        expect(datacenters.get.size).to eq(2)
        expect(datacenters.get.first).to eq('dc1')
      end
    end

    describe 'GET With headers' do
      it 'empty headers' do
        json = JSON.generate(body)

        stub_request(:get, key_url).to_return(OpenStruct.new(body: json, headers: nil))

        datacenters = Diplomat::Datacenter.new

        meta = {}
        expect(datacenters.get(meta).size).to eq(2)
        expect(datacenters.get(meta)[0]).to eq('dc1')
        expect(meta.length).to eq(0)
      end

      it 'filled headers' do
        json = JSON.generate(body)

        stub_request(:get, key_url)
          .to_return(OpenStruct.new(body: json, headers: headers))

        datacenters = Diplomat::Datacenter.new

        meta = {}
        s = datacenters.get(meta)
        expect(s.first).to eq('dc1')
        expect(meta[:index]).to eq('8')
        expect(meta[:knownleader]).to eq('true')
        expect(meta[:lastcontact]).to eq('0')
      end
    end
  end
end
