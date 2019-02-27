require 'spec_helper'

describe Diplomat::Service do
  context 'services' do
    let(:key) { 'toast' }
    let(:key_url) { "http://localhost:8500/v1/catalog/service/#{key}" }
    let(:key_url_with_indexoption) { "http://localhost:8500/v1/catalog/service/#{key}?index=5" }
    let(:key_url_with_waitoption) { "http://localhost:8500/v1/catalog/service/#{key}?wait=6s" }
    let(:key_url_with_alloptions) { "http://localhost:8500/v1/catalog/service/#{key}?wait=5m&index=3&dc=somedc" }
    let(:key_url_with_datacenteroption) { "http://localhost:8500/v1/catalog/service/#{key}?dc=somedc" }
    let(:key_url_with_tagoption) { "http://localhost:8500/v1/catalog/service/#{key}?tag=sometag" }
    let(:services_url_with_datacenteroption) { 'http://localhost:8500/v1/catalog/services?dc=somedc' }
    let(:body) do
      [
        {
          'Node' => 'foo',
          'Address' => '10.1.10.12',
          'ServiceID' => key,
          'ServiceName' => key,
          'ServiceTags' => ['sometag'],
          'ServicePort' => '70457'
        },
        {
          'Node' => 'bar',
          'Address' => '10.1.10.13',
          'ServiceID' => key,
          'ServiceName' => key,
          'ServiceTags' => %w[sometag anothertag],
          'ServicePort' => '70457'
        }
      ]
    end
    let(:headers) do
      {
        'x-consul-index' => '8',
        'x-consul-knownleader' => 'true',
        'x-consul-lastcontact' => '0'
      }
    end
    let(:body_all) do
      {
        service1: ['tag one', 'tag two', 'tag three'],
        service2: ['tag four']
      }
    end
    before do
      Diplomat.configuration.acl_token = nil
    end
    describe 'GET' do
      it ':first' do
        json = JSON.generate(body)
        stub_request(:get, key_url)
          .to_return(OpenStruct.new(body: json))
        service = Diplomat::Service.new
        expect(service.get('toast').Node).to eq('foo')
      end
      it ':all' do
        json = JSON.generate(body)
        stub_request(:get, key_url)
          .to_return(OpenStruct.new(body: json))
        service = Diplomat::Service.new
        expect(service.get('toast', :all).size).to eq(2)
        expect(service.get('toast', :all).first.Node).to eq('foo')
      end
    end
    describe 'GET With Options' do
      it 'empty headers' do
        json = JSON.generate(body)
        stub_request(:get, key_url)
          .to_return(OpenStruct.new(body: json, headers: nil))
        service = Diplomat::Service.new
        meta = {}
        s = service.get('toast', :first, {}, meta)
        expect(s.Node).to eq('foo')
        expect(meta.length).to eq(0)
      end
      it 'filled headers' do
        json = JSON.generate(body)
        stub_request(:get, key_url)
          .to_return(OpenStruct.new(body: json, headers: headers))
        service = Diplomat::Service.new
        meta = {}
        s = service.get('toast', :first, {}, meta)
        expect(s.Node).to eq('foo')
        expect(meta[:index]).to eq('8')
        expect(meta[:knownleader]).to eq('true')
        expect(meta[:lastcontact]).to eq('0')
      end

      it 'index option' do
        json = JSON.generate(body)
        stub_request(:get, key_url_with_indexoption)
          .to_return(OpenStruct.new(body: json, headers: headers))
        service = Diplomat::Service.new
        options = { index: '5' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'wait option' do
        json = JSON.generate(body)
        stub_request(:get, key_url_with_waitoption)
          .to_return(OpenStruct.new(body: json, headers: headers))
        service = Diplomat::Service.new
        options = { wait: '6s' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'datacenter option' do
        json = JSON.generate(body)
        stub_request(:get, key_url_with_datacenteroption)
          .to_return(OpenStruct.new(body: json, headers: headers))
        service = Diplomat::Service.new
        options = { dc: 'somedc' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'bad datacenter option' do
        stub_request(:get, key_url_with_datacenteroption)
          .to_return(status: [500, 'Internal Server Error'])
        service = Diplomat::Service.new
        options = { dc: 'somedc' }
        expect { service.get('toast', :first, options) }.to raise_error(Diplomat::PathNotFound)
      end

      it 'tag option' do
        json = JSON.generate(body)
        stub_request(:get, key_url_with_tagoption)
          .to_return(OpenStruct.new(body: json, headers: headers))
        service = Diplomat::Service.new
        options = { tag: 'sometag' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'all options' do
        json = JSON.generate(body)
        stub_request(:get, key_url_with_alloptions)
          .to_return(OpenStruct.new(body: json, headers: headers))
        service = Diplomat::Service.new
        options = { wait: '5m', index: '3', dc: 'somedc' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end
    end

    describe 'GET ALL' do
      let(:service_one_tag) { 'tag one' }
      let(:service_two_tag) { 'tag four' }

      it 'lists all the services for the default datacenter' do
        json = JSON.generate(body_all)
        stub_request(:get, 'http://localhost:8500/v1/catalog/services')
          .to_return(OpenStruct.new(body: json))
        service = Diplomat::Service.new
        expect(service.get_all.service1).to be_an(Array)
        expect(service.get_all.service2).to be_an(Array)
        expect(service.get_all.service1.first).to eq(service_one_tag)
        expect(service.get_all.service2.first).to eq(service_two_tag)
      end
      it 'lists all the services for the specified datacenter' do
        json = JSON.generate(body_all)
        stub_request(:get, services_url_with_datacenteroption)
          .to_return(OpenStruct.new(body: json))
        options = { dc: 'somedc' }
        service = Diplomat::Service.new
        expect(service.get_all(options).service1).to be_an(Array)
        expect(service.get_all(options).service2).to be_an(Array)
        expect(service.get_all(options).service1.first).to eq(service_one_tag)
        expect(service.get_all(options).service2.first).to eq(service_two_tag)
      end
    end

    describe 'Register service' do
      let(:register_service_url) { 'http://localhost:8500/v1/agent/service/register' }
      let(:deregister_service_url) { 'http://localhost:8500/v1/agent/service/deregister' }
      let(:token) { '80a6200c-6ec9-42e1-816a-e40007e732a6' }
      let(:service_definition) do
        {
          name: 'test_service_definition',
          check: {
            script: 'echo "true"',
            interval: '1s'
          }
        }
      end

      it 'can register a service' do
        json_request = JSON.dump(service_definition)
        stub_request(:put, register_service_url)
          .with(body: json_request).to_return(OpenStruct.new(body: '', status: 200))
        service = Diplomat::Service.new
        s = service.register(service_definition)
        expect(s).to eq(true)
      end

      it 'can register a service with a token' do
        json_request = JSON.dump(service_definition)
        stub_request(:put, register_service_url)
          .with(body: json_request, headers: { 'X-Consul-Token' => token })
          .to_return(OpenStruct.new(body: '', status: 200))
        Diplomat.configure do |config|
          config.acl_token = token
        end
        service = Diplomat::Service.new
        s = service.register(service_definition)
        expect(s).to eq(true)
      end

      it 'can deregister a service' do
        url = "#{deregister_service_url}/#{service_definition[:name]}"
        stub_request(:put, url)
          .to_return(OpenStruct.new(body: '', status: 200))
        service = Diplomat::Service.new
        s = service.deregister(service_definition[:name])
        expect(s).to eq(true)
      end
    end

    describe 'Register external service' do
      let(:register_service_url) { 'http://localhost:8500/v1/catalog/register' }
      let(:deregister_service_url) { 'http://localhost:8500/v1/catalog/deregister' }

      let(:service_definition) do
        {
          Datacenter: :dc1,
          Node: :google,
          Address: 'www.google.com',
          Service: {
            Service: :search,
            Port: 80
          }
        }
      end

      let(:deregister_definition) do
        {
          Datacenter: :dc1,
          Node: :google
        }
      end

      it 'can register a service' do
        json_request = JSON.dump(service_definition)
        stub_request(:put, register_service_url)
          .with(body: json_request).to_return(OpenStruct.new(body: '', status: 200))
        service = Diplomat::Service.new
        s = service.register_external(service_definition)
        expect(s).to eq(true)
      end

      it 'can deregister a service' do
        json_request = JSON.dump(deregister_definition)
        stub_request(:put, deregister_service_url)
          .with(body: json_request).to_return(OpenStruct.new(body: '', status: 200))
        service = Diplomat::Service.new
        s = service.deregister_external(deregister_definition)
        expect(s).to eq(true)
      end
    end

    describe '#maintenance' do
      let(:service_id) { 'TEST1' }
      let(:enable_url) { 'http://localhost:8500/v1/agent/service/maintenance/TEST1?enable=true' }
      let(:disable_url) { 'http://localhost:8500/v1/agent/service/maintenance/TEST1?enable=false' }
      let(:message_url) { enable_url + '&reason=My+Maintenance+Reason' }

      context 'when enabling maintenance' do
        let(:s) do
          proc do |reason|
            stub_request(:put, enable_url)
              .to_return(OpenStruct.new(body: '', status: 200))
            service = Diplomat::Service.new
            service.maintenance(service_id, enable: 'true', reason: reason)
          end
        end

        it 'enables maintenance for a service' do
          expect(s.call).to eq(true)
        end

        it 'returns a boolean' do
          expect(s.call).to be(true).or be(false)
        end

        it 'adds a reason' do
          reason = 'My Maintenance Reason'
          stub_request(:put, message_url)
            .to_return(OpenStruct.new(body: '', status: 200))
          service = Diplomat::Service.new
          s_message = service.maintenance(service_id, enable: 'true', reason: reason)
          expect(s_message).to eq(true)
        end
      end

      context 'when disabling maintenance' do
        let(:s) do
          proc do
            stub_request(:put, disable_url)
              .to_return(OpenStruct.new(body: '', status: 200))
            service = Diplomat::Service.new
            service.maintenance(service_id, enable: 'false')
          end
        end

        it 'disables maintenance for a service' do
          expect(s.call).to eq(true)
        end

        it 'returns a boolean' do
          expect(s.call).to be(true).or be(false)
        end
      end
    end
  end

  context 'acl' do
    let(:acl_token_1) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f1' }
    let(:acl_token_2) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f2' }
    describe 'GET' do
      let(:service_name) { 'toast' }
      it 'token empty' do
        stub_without_token = stub_request(:get, "http://localhost:8500/v1/catalog/service/#{service_name}")
                             .to_return(OpenStruct.new(body: '{}'))
        stub_with_token = stub_request(:get, "http://localhost:8500/v1/catalog/service/#{service_name}")
                          .with(headers: { 'X-Consul-Token' => acl_token_1 }).to_return(OpenStruct.new(body: '{}'))
        Diplomat.configuration.acl_token = nil
        service = Diplomat::Service.new
        service.get(service_name)
        expect(stub_without_token).to have_been_requested
        expect(stub_with_token).not_to have_been_requested
      end
      it 'token specified in configuration' do
        stub_request(:get, "http://localhost:8500/v1/catalog/service/#{service_name}")
          .with(headers: { 'X-Consul-Token' => acl_token_1 }).to_return(OpenStruct.new(body: '{}'))
        Diplomat.configuration.acl_token = acl_token_1
        service = Diplomat::Service.new
        service.get(service_name)
      end
      it 'token specified in method call' do
        stub_request(:get, "http://localhost:8500/v1/catalog/service/#{service_name}")
          .with(headers: { 'X-Consul-Token' => acl_token_2 }).to_return(OpenStruct.new(body: '{}'))
        Diplomat.configuration.acl_token = acl_token_1
        service = Diplomat::Service.new
        service.get(service_name, :first, token: acl_token_2)
      end
    end
    describe 'GET_ALL' do
      let(:service_name) { 'toast' }
      it 'token empty' do
        stub_without_token = stub_request(:get, 'http://localhost:8500/v1/catalog/services')
                             .to_return(OpenStruct.new(body: '{}'))
        stub_with_token = stub_request(:get, 'http://localhost:8500/v1/catalog/services')
                          .with(headers: { 'X-Consul-Token' => acl_token_1 }).to_return(OpenStruct.new(body: '{}'))
        Diplomat.configuration.acl_token = nil
        service = Diplomat::Service.new
        service.get_all
        expect(stub_without_token).to have_been_requested
        expect(stub_with_token).not_to have_been_requested
      end
      it 'token specified in configuration' do
        stub_request(:get, 'http://localhost:8500/v1/catalog/services')
          .with(headers: { 'X-Consul-Token' => acl_token_1 }).to_return(OpenStruct.new(body: '{}'))
        Diplomat.configuration.acl_token = acl_token_1
        service = Diplomat::Service.new
        service.get_all
      end
      it 'token specified in method call' do
        stub_request(:get, 'http://localhost:8500/v1/catalog/services')
          .with(headers: { 'X-Consul-Token' => acl_token_2 }).to_return(OpenStruct.new(body: '{}'))
        Diplomat.configuration.acl_token = acl_token_1
        service = Diplomat::Service.new
        service.get_all(token: acl_token_2)
      end
    end
  end
end
