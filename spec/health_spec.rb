# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Health do
  let(:faraday) { fake }

  describe '#node' do
    let(:node_definition) do
      [
        {
          Node: 'foobar',
          CheckID: 'serfHealth',
          Name: 'Serf Health Status',
          Status: 'passing',
          Notes: '',
          Output: '',
          ServiceID: '',
          ServiceName: ''
        },
        {
          Node: 'foobar',
          CheckID: 'service:redis',
          Name: 'Service \'redis\' check',
          Status: 'passing',
          Notes: '',
          Output: '',
          ServiceID: 'redis',
          ServiceName: 'redis'
        }
      ]
    end
    let(:json) { node_definition.to_json }
    let(:ch) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      health.node('foobar')
    end

    it 'should return an array of checks' do
      expect(ch).to be_a_kind_of(Array)
    end

    it 'should return an OpenStruct for each check' do
      ch.each do |check|
        expect(check).to be_a_kind_of(OpenStruct)
      end
    end

    it 'should return the node name' do
      expect(ch.first['Node']).to eq('foobar')
    end

    it 'should check with \'dc\' option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { dc: 'some-dc' }

      expect(health.node('foobar', options: options).first['Node']).to eq('foobar')
    end
  end

  describe '#checks' do
    let(:check_definition) do
      [
        {
          Node: 'foobar',
          CheckID: 'service:redis',
          Name: 'Service \'redis\' check',
          Status: 'passing',
          Notes: '',
          Output: '',
          ServiceID: 'redis',
          ServiceName: 'redis'
        }
      ]
    end
    let(:json) { check_definition.to_json }
    let(:ch) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      health.checks('foobar')
    end

    it 'should check with dc option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { dc: 'some-dc' }

      expect(health.checks('foobar', options: options).first['Node']).to eq('foobar')
    end

    it 'should return the node name' do
      expect(ch.first['Node']).to eq('foobar')
    end

    it 'should return an array of checks' do
      expect(ch).to be_a_kind_of(Array)
    end

    it 'should return an OpenStruct for each check' do
      ch.each do |check|
        expect(check).to be_a_kind_of(OpenStruct)
      end
    end
  end

  describe '#service' do
    let(:service_definition) do
      [
        {
          Node: {
            Node: 'foobar',
            Address: '10.1.10.12'
          },
          Service: {
            ID: 'redis',
            Service: 'redis',
            Tags: ['v1'],
            Port: 8000
          },
          Checks: [
            {
              Node: 'foobar',
              CheckID: 'service:redis',
              Name: 'Service \'redis\' check',
              Status: 'passing',
              Notes: '',
              Output: '',
              ServiceID: 'redis',
              ServiceName: 'redis'
            },
            {
              Node: 'foobar',
              CheckID: 'serfHealth',
              Name: 'Serf Health Status',
              Status: 'failing',
              Notes: '',
              Output: '',
              ServiceID: '',
              ServiceName: ''
            }
          ]
        }
      ]
    end
    let(:json) { service_definition.to_json }
    let(:ch) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      health.service('foobar')
    end

    it 'should return the node name' do
      expect(ch.first['Node']['Node']).to eq('foobar')
    end

    it 'should check service with dc option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { dc: 'some-dc' }

      expect(health.service('foobar', options: options).first['Node']['Node']).to eq('foobar')
    end

    it 'should check service with near option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { near: 'some-node' }

      expect(health.service('foobar', options: options).first['Node']['Node']).to eq('foobar')
    end

    it 'should check service with passing option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { passing: true }

      expect(health.service('foobar', options: options).first['Checks'].first['CheckID']).to eq('service:redis')
    end

    it 'should check service with cached option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { cached: true }

      expect(health.service('foobar', options: options).first['Checks'].first['CheckID']).to eq('service:redis')
    end

    it 'check service with tag options' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { tag: 'v1' }

      expect(health.service('foobar', options: options).first['Node']['Node']).to eq('foobar')
    end

    it 'check service with multiple tag options' do
      stub_request(:get, "http://localhost:8500/v1/health/service/foobar?tag=v1&tag=v2")
        .and_return(body: json)
      health = Diplomat::Health

      expect(health.service('foobar', tag: ['v1', 'v2']).first['Node']['Node']).to eq('foobar')
    end

    it 'should check service with node-meta option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { node_meta: 'rack:rack-2' }

      expect(health.service('foobar', options: options).first['Node']['Node']).to eq('foobar')
    end

    it 'should return an array of checks' do
      expect(ch).to be_a_kind_of(Array)
    end

    it 'should return an OpenStruct for each check' do
      ch.each do |check|
        expect(check).to be_a_kind_of(OpenStruct)
      end
    end
  end

  describe '#state' do
    let(:state_definition) do
      [
        {
          Node: 'foobar',
          CheckID: 'serfHealth',
          Name: 'Serf Health Status',
          Status: 'passing',
          Notes: '',
          Output: '',
          ServiceID: '',
          ServiceName: ''
        },
        {
          Node: 'foobar',
          CheckID: 'service:redis',
          Name: 'Service \'redis\' check',
          Status: 'passing',
          Notes: '',
          Output: '',
          ServiceID: 'redis',
          ServiceName: 'redis'
        }
      ]
    end
    let(:json) { state_definition.to_json }
    let(:ch) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      health.state('foobar')
    end

    it 'should return the state' do
      expect(ch.first['Node']).to eq('foobar')
    end

    it 'should return state with dc options' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      health = Diplomat::Health.new(faraday)
      options = { dc: 'some-dc' }

      expect(health.state('foobar', options: options).first['Node']).to eq('foobar')
    end

    it 'should return an array of checks' do
      expect(ch).to be_a_kind_of(Array)
    end

    it 'should return an OpenStruct for each check' do
      ch.each do |check|
        expect(check).to be_a_kind_of(OpenStruct)
      end
    end
  end
end
