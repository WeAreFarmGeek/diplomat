require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Event do
  let(:empty_json) { '[]' }
  let(:events_json) do
    '[{"ID":"b8a5d478-c370-28b1-cd04-9547877bf767","Name":"test","Payload":"eyBrZXk6IDEgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":327},
    {"ID":"7261716d-edf1-398e-8d14-e29eea37bd9d","Name":"test","Payload":"eyBrZXk6IDIgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":328},
    {"ID":"9c98eddb-5bbe-9035-435f-2385b3484203","Name":"test","Payload":"eyBrZXk6IDMgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":329},
    {"ID":"426f6761-3c67-d3f1-f228-a8d958d59ab3","Name":"test","Payload":"eyBrZXk6IDQgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":330}]'
  end
  let(:events_next_json) do
    '[{"ID":"b8a5d478-c370-28b1-cd04-9547877bf767","Name":"test","Payload":"eyBrZXk6IDEgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":327},
    {"ID":"7261716d-edf1-398e-8d14-e29eea37bd9d","Name":"test","Payload":"eyBrZXk6IDIgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":328},
    {"ID":"9c98eddb-5bbe-9035-435f-2385b3484203","Name":"test","Payload":"eyBrZXk6IDMgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":329},
    {"ID":"426f6761-3c67-d3f1-f228-a8d958d59ab3","Name":"test","Payload":"eyBrZXk6IDQgfQ==",
    "NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":330}]'
  end
  let(:events_expected) do
    [
      { name: 'test', payload: '{ key: 1 }' },
      { name: 'test', payload: '{ key: 2 }' },
      { name: 'test', payload: '{ key: 3 }' },
      { name: 'test', payload: '{ key: 4 }' }
    ]
  end
  let(:events_next_expected) do
    [
      { name: 'test', payload: '{ key: 1 }' },
      { name: 'test', payload: '{ key: 2 }' },
      { name: 'test', payload: '{ key: 3 }' },
      { name: 'test', payload: '{ key: 4 }' }
    ]
  end
  let(:event_name) { 'test' }
  let(:event_first) do
    {
      value: {
        name: 'test',
        payload: '{ key: 1 }'
      },
      token: 'b8a5d478-c370-28b1-cd04-9547877bf767'
    }
  end
  let(:token_mid) { '7261716d-edf1-398e-8d14-e29eea37bd9d' }
  let(:event_mid) do
    {
      value: {
        name: 'test',
        payload: '{ key: 3 }'
      },
      token: '9c98eddb-5bbe-9035-435f-2385b3484203'
    }
  end
  let(:event_last) do
    {
      value: {
        name: 'test',
        payload: '{ key: 4 }'
      },
      token: '426f6761-3c67-d3f1-f228-a8d958d59ab3'
    }
  end
  let(:event_next) do
    {
      value: {
        name: 'test',
        payload: '{ key: 4 }'
      },
      token: '426f6761-3c67-d3f1-f228-a8d958d59ab3'
    }
  end

  describe '#get_all' do
    before do
      Diplomat.configuration.acl_token = nil
    end
    context 'empty list' do
      let(:faraday) { double('Faraday') }

      it 'default args act the same as (:reject, _)' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: empty_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect { ev.get_all(event_name) }.to raise_error(Diplomat::EventNotFound, event_name)
      end
      it 'throws when asked to :reject' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: empty_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect { ev.get_all(event_name, :reject) }.to raise_error(Diplomat::EventNotFound, event_name)
      end
      it 'retries and returns when asked to :wait' do
        expect(faraday).to receive(:get).twice.and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: empty_json),
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '69' }, body: events_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(event_name, :wait)).to eql(events_expected)
      end
    end

    context 'non-empty list' do
      let(:faraday) { double('Faraday') }

      it 'default args act the same as (_, :return)' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(event_name)).to eql(events_expected)
      end

      it 'throws when asked to :reject' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect { ev.get_all(event_name, :reject, :reject) }.to raise_error(Diplomat::EventAlreadyExists, event_name)
      end

      it 'returns when asked to :return' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(event_name, :reject, :return)).to eql(events_expected)
      end

      it 'retries and returns when asked to :wait' do
        expect(faraday).to receive(:get).twice.and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json),
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '69' }, body: events_next_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(event_name, :reject, :wait)).to eql(events_next_expected)
      end
    end
  end

  describe '#get' do
    before do
      Diplomat.configuration.acl_token = nil
    end
    context 'non-empty list' do
      let(:faraday) { double('Faraday') }

      it 'gets first item' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(event_name, :first)).to eql(event_first)
      end

      it 'gets last item' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(event_name, :last)).to eql(event_last)
      end

      it 'gets mid-sequence item' do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(event_name, token_mid)).to eql(event_mid)
      end

      it 'retries and returns next item' do
        expect(faraday).to receive(:get).twice.and_return(
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '42' }, body: events_json),
          OpenStruct.new(status: 200, headers: { 'x-consul-index' => '69' }, body: events_next_json)
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(event_name, :next)).to eql(event_next)
      end
    end
  end

  context 'acl' do
    let(:acl_token) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f1' }
    let(:faraday) { fake }

    describe 'FIRE' do
      it 'token empty' do
        stub_request(:put, "http://localhost:8500/v1/event/fire/#{event_name}")
        Diplomat.configuration.acl_token = nil
        ev = Diplomat::Event.new

        ev.fire(event_name)
      end

      it 'token specified' do
        stub_request(:put, "http://localhost:8500/v1/event/fire/#{event_name}")
          .with(headers: { 'X-Consul-Token' => acl_token })
        Diplomat.configuration.acl_token = acl_token
        ev = Diplomat::Event.new

        ev.fire(event_name)
      end
    end

    describe 'GET_ALL' do
      it 'token empty' do
        stub_without_token = stub_request(:get, 'http://localhost:8500/v1/event/list')
                             .to_return(OpenStruct.new(body: events_json))
        stub_with_token = stub_request(:get, 'http://localhost:8500/v1/event/list')
                          .with(headers: { 'X-Consul-Token' => acl_token })
                          .to_return(OpenStruct.new(body: events_json))

        Diplomat.configuration.acl_token = nil
        ev = Diplomat::Event.new

        ev.get_all
        expect(stub_without_token).to have_been_requested
        expect(stub_with_token).not_to have_been_requested
      end

      it 'token specified' do
        stub_request(:get, 'http://localhost:8500/v1/event/list')
          .with(headers: { 'X-Consul-Token' => acl_token }).to_return(OpenStruct.new(body: events_json))
        Diplomat.configuration.acl_token = acl_token
        ev = Diplomat::Event.new

        ev.get_all
      end
    end

    describe 'GET' do
      it 'token empty' do
        stub_without_token = stub_request(:get, 'http://localhost:8500/v1/event/list')
                             .to_return(OpenStruct.new(body: events_json))
        stub_with_token = stub_request(:get, 'http://localhost:8500/v1/event/list')
                          .with(headers: { 'X-Consul-Token' => acl_token })
                          .to_return(OpenStruct.new(body: events_json))
        Diplomat.configuration.acl_token = nil
        ev = Diplomat::Event.new

        ev.get
        expect(stub_without_token).to have_been_requested
        expect(stub_with_token).not_to have_been_requested
      end

      it 'token specified' do
        stub_request(:get, 'http://localhost:8500/v1/event/list')
          .with(headers: { 'X-Consul-Token' => acl_token }).to_return(OpenStruct.new(body: events_json))
        Diplomat.configuration.acl_token = acl_token
        ev = Diplomat::Event.new

        ev.get
      end
    end
  end
end
