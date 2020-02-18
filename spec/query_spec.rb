# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::Query do
  let(:faraday) { fake }
  let(:base_options) { {} }
  let(:query_key) { '8f246b77-f3e1-ff88-5b48-8ec93abf3e05' }

  describe '#get' do
    let(:query_definition) do
      [
        {
          ID: '8f246b77-f3e1-ff88-5b48-8ec93abf3e05',
          Name: 'my-query',
          Session: 'adf4238a-882b-9ddc-4a9d-5b6758e4159e',
          Token: '<hidden>',
          Service: {
            Service: 'redis',
            Failover: {
              NearestN: 3,
              Datacenters: %w[dc1 dc2]
            },
            OnlyPassing: false,
            Tags: ['primary', '!experimental']
          },
          DNS: {
            TTL: '10s'
          },
          RaftIndex: {
            CreateIndex: 23,
            ModifyIndex: 42
          }
        }
      ]
    end
    let(:json) { query_definition.to_json }
    subject do
      lambda do |options|
        faraday.stub(:get).and_return(OpenStruct.new(body: json))
        query = Diplomat::Query.new(faraday)
        query.get(query_key, options: options)
      end
    end

    it 'should return query ID' do
      expect(subject.call(base_options).first['ID']).to eq(query_key)
    end

    it 'should get query with dc options' do
      options = { dc: 'some-dc' }
      expect(subject.call(options).first['ID']).to eq(query_key)
    end

    it 'should return an array of prepared queries' do
      expect(subject.call(base_options)).to be_a_kind_of(Array)
    end

    it 'should return an OpenStruct for each query' do
      subject.call(base_options).each do |query|
        expect(query).to be_a_kind_of(OpenStruct)
      end
    end
  end

  describe '#get_all' do
    let(:query_definition) do
      [
        {
          ID: '8f246b77-f3e1-ff88-5b48-8ec93abf3e05',
          Name: 'my-query',
          Session: 'adf4238a-882b-9ddc-4a9d-5b6758e4159e',
          Token: '<hidden>',
          Service: {
            Service: 'redis',
            Failover: {
              NearestN: 3,
              Datacenters: %w[dc1 dc2]
            },
            OnlyPassing: false,
            Tags: ['primary', '!experimental']
          },
          DNS: {
            TTL: '10s'
          },
          RaftIndex: {
            CreateIndex: 23,
            ModifyIndex: 42
          }
        }
      ]
    end
    let(:json) { query_definition.to_json }
    let(:cq) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      query = Diplomat::Query.new(faraday)
      query.get_all
    end

    it 'should return query ID' do
      expect(cq.first['ID']).to eq('8f246b77-f3e1-ff88-5b48-8ec93abf3e05')
    end

    it 'should return an array of prepared queries' do
      expect(cq).to be_a_kind_of(Array)
    end

    it 'should return an OpenStruct for each query' do
      cq.each do |query|
        expect(query).to be_a_kind_of(OpenStruct)
      end
    end
  end

  describe '#create' do
    let(:query_definition) do
      {
        Name: 'my-query',
        Session: 'adf4238a-882b-9ddc-4a9d-5b6758e4159e',
        Token: '',
        Service: {
          Service: 'redis',
          Failover: {
            NearestN: 3,
            Datacenters: %w[dc1 dc2]
          },
          Near: 'node1',
          OnlyPassing: false,
          Tags: ['primary', '!experimental']
        },
        DNS: {
          TTL: '10s'
        }
      }
    end
    let(:valid_return) do
      {
        'ID' => '8f246b77-f3e1-ff88-5b48-8ec93abf3e05'
      }
    end
    let(:return_json) { valid_return.to_json }
    subject do
      lambda do |options, status|
        faraday.stub(:post).and_return(OpenStruct.new(body: return_json, status: status))
        query = Diplomat::Query.new(faraday)
        query.create(query_definition, options: options)
      end
    end

    it 'should create query with dc options' do
      options = { dc: 'some-dc' }
      expect(subject.call(options, 200)).to eq(valid_return)
    end

    it 'should raise \'Diplomat::UnknownStatus\' when return status not 200' do
      expect { subject.call(base_options, 404) }.to raise_error(Diplomat::UnknownStatus)
    end

    it 'should return query ID of new query' do
      expect(subject.call(base_options, 200)).to eq(valid_return)
    end

    it 'should return a Hash' do
      expect(subject.call(base_options, 200)).to be_a_kind_of(Hash)
    end
  end

  describe '#delete' do
    subject do
      lambda do |options, status|
        faraday.stub(:delete).and_return(OpenStruct.new(body: '', status: status))
        query = Diplomat::Query.new(faraday)
        query.delete(query_key, options: options)
      end
    end

    it 'should delete query with dc options' do
      options = { dc: 'some-dc' }
      expect(subject.call(options, 200)).to be_truthy
    end

    it 'should return true on successful delete' do
      expect(subject.call(base_options, 200)).to be_truthy
    end

    it 'should return false on failed delete' do
      expect(subject.call(base_options, 404)).to be_falsy
    end
  end

  describe '#update' do
    let(:query_definition) do
      {
        Name: 'my-query',
        Session: 'adf4238a-882b-9ddc-4a9d-5b6758e4159e',
        Token: '',
        Service: {
          Service: 'redis',
          Failover: {
            NearestN: 3,
            Datacenters: %w[dc1 dc2]
          },
          Near: 'node1',
          OnlyPassing: false,
          Tags: ['primary', '!experimental']
        },
        DNS: {
          TTL: '10s'
        }
      }
    end
    let(:json) { query_definition.to_json }
    subject do
      lambda do |status|
        faraday.stub(:put).and_return(OpenStruct.new(body: '', status: status))
        query = Diplomat::Query.new(faraday)
        query.update(query_key, json)
      end
    end

    it 'should create query with dc options' do
      faraday.stub(:put).and_return(OpenStruct.new(body: '', status: 200))
      query = Diplomat::Query.new(faraday)
      options = { dc: 'some-dc' }
      expect(query.update(query_key, json, options: options)).to be_truthy
    end

    it 'should return true on successful update' do
      expect(subject.call(200)).to be_truthy
    end

    it 'should return false on a failed update' do
      expect(subject.call(404)).to be_falsy
    end
  end

  describe '#execute' do
    let(:valid_return) do
      {
        Service: 'redis',
        Nodes: [{
          Node: {
            Node: 'foobar',
            Address: '10.1.10.12',
            TaggedAddresses: {
              lan: '10.1.10.12',
              wan: '10.1.10.12'
            }
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
              Status: 'passing',
              Notes: '',
              Output: '',
              ServiceID: '',
              ServiceName: ''
            }
          ],
          DNS: {
            TTL: '10s'
          },
          Datacenter: 'dc3',
          Failovers: 2
        }]
      }
    end
    let(:json) { valid_return.to_json }

    context 'when given different options' do
      subject do
        lambda do |options|
          faraday.stub(:get).and_return(OpenStruct.new(body: json))
          query = Diplomat::Query.new(faraday)
          query.execute(query_key, options: options)
        end
      end
      let(:options) do
        {
          dc: 'some-dc',
          near: 'some-node',
          limit: 3
        }
      end

      it 'should create query with options' do
        options.each do |k, v|
          expect(subject.call(k => v)['Nodes'].first['Node']['Node']).to eq('foobar')
        end
      end
    end

    it 'should return an OpenStruct of results' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      query = Diplomat::Query.new(faraday)
      expect(query.execute(query_key)).to be_a_kind_of(OpenStruct)
    end
  end

  describe '#explain' do
    let(:valid_return) do
      {
        Query: {
          ID: '8f246b77-f3e1-ff88-5b48-8ec93abf3e05',
          Session: 'adf4238a-882b-9ddc-4a9d-5b6758e4159e',
          Token: '<hidden>',
          Name: 'geo-db',
          Template: {
            Type: 'name_prefix_match',
            Regexp: '^geo-db-(.*?)-([^\\-]+?)$'
          },
          Service: {
            Service: 'mysql-customer',
            Failover: {
              NearestN: 3,
              Datacenters: %w[dc1 dc2]
            },
            OnlyPassing: true,
            Tags: ['primary']
          }
        }
      }
    end
    let(:json) { valid_return.to_json }
    let(:cq) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      query = Diplomat::Query.new(faraday)
      query.explain(query_key)
    end

    it 'should return query explaination' do
      expect(cq['Query']['ID']).to eq('8f246b77-f3e1-ff88-5b48-8ec93abf3e05')
    end

    it 'should return an OpenStruct' do
      expect(cq).to be_a_kind_of(OpenStruct)
    end

    it 'should query with dc option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      query = Diplomat::Query.new(faraday)
      options = { dc: 'some-dc' }
      expect(query.explain(query_key, options: options)['Query']['ID']).to eq('8f246b77-f3e1-ff88-5b48-8ec93abf3e05')
    end
  end
end
