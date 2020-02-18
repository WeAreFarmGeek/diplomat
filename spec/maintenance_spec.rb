# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::Maintenance do
  let(:faraday) { fake }
  let(:req) { fake }

  context 'enabled' do
    it 'enabled' do
      json = JSON.generate(
        [
          {
            'Node' => 'foobar',
            'CheckID' => 'serfHealth',
            'Name' => 'Serf Health Status',
            'Status' => 'passing',
            'Notes' => '',
            'Output' => '',
            'ServiceID' => '',
            'ServiceName' => ''
          },
          {
            'Node' => 'foobar',
            'CheckID' => '_node_maintenance',
            'Name' => 'Node Maintenance Mode',
            'Status' => 'critical',
            'Notes' => 'foo bar',
            'Output' => '',
            'ServiceID' => '',
            'ServiceName' => '',
            'CreateIndex' => 135_459,
            'ModifyIndex' => 135_459
          }
        ]
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(maintenance.enabled('foobar')).to eq(enabled: true, reason: 'foo bar')
    end

    it 'disabled' do
      json = JSON.generate(
        [
          {
            'Node' => 'foobar',
            'CheckID' => 'serfHealth',
            'Name' => 'Serf Health Status',
            'Status' => 'passing',
            'Notes' => '',
            'Output' => '',
            'ServiceID' => '',
            'ServiceName' => ''
          }
        ]
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(maintenance.enabled('foobar')).to eq(enabled: false, reason: nil)
    end
  end

  context 'enable' do
    it 'enables' do
      maintenance = Diplomat::Maintenance.new
      stub_request(:put, 'http://localhost:8500/v1/agent/maintenance?enable=true')
        .to_return(OpenStruct.new(body: '', status: 200))
      expect(maintenance.enable(true)).to eq(true)
    end

    it 'disables' do
      maintenance = Diplomat::Maintenance.new
      stub_request(:put, 'http://localhost:8500/v1/agent/maintenance?enable=false')
        .to_return(OpenStruct.new(body: '', status: 200))
      expect(maintenance.enable(false)).to eq(true)
    end

    it 'with reason' do
      maintenance = Diplomat::Maintenance.new
      stub_request(:put, 'http://localhost:8500/v1/agent/maintenance?enable=true&reason=foobar')
        .to_return(OpenStruct.new(body: '', status: 200))
      expect(maintenance.enable(true, 'foobar')).to eq(true)
    end

    it 'with dc' do
      maintenance = Diplomat::Maintenance.new
      stub_request(:put, 'http://localhost:8500/v1/agent/maintenance?enable=true&reason=foobar&dc=abc')
        .to_return(OpenStruct.new(body: '', status: 200))
      expect(maintenance.enable(true, 'foobar', dc: 'abc')).to eq(true)
    end
  end
end
