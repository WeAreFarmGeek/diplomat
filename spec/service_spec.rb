require 'spec_helper'

describe Diplomat::Service do
  let(:faraday) { fake }

  context 'services' do
    let(:key) { 'toast' }
    let(:key_url) { "/v1/catalog/service/#{key}" }
    let(:key_url_with_alloptions) { "/v1/catalog/service/#{key}?wait=5m&index=3&dc=somedc" }
    let(:key_url_with_indexoption) { "/v1/catalog/service/#{key}?index=5" }
    let(:key_url_with_waitoption) { "/v1/catalog/service/#{key}?wait=6s" }
    let(:key_url_with_datacenteroption) { "/v1/catalog/service/#{key}?dc=somedc" }
    let(:key_url_with_tagoption) { "/v1/catalog/service/#{key}?tag=sometag" }
    let(:services_url_with_datacenteroption) { '/v1/catalog/services?dc=somedc' }
    let(:body) do
      [
        {
          'Node'        => 'foo',
          'Address'     => '10.1.10.12',
          'ServiceID'   => key,
          'ServiceName' => key,
          'ServiceTags' => ['sometag'],
          'ServicePort' => '70457'
        },
        {
          'Node'        => 'bar',
          'Address'     => '10.1.10.13',
          'ServiceID'   => key,
          'ServiceName' => key,
          'ServiceTags' => %w[sometag anothertag],
          'ServicePort' => '70457'
        }
      ]
    end
    let(:body_all) do
      {
        service1: ['tag one', 'tag two', 'tag three'],
        service2: ['tag four']
      }
    end
    let(:headers) do
      {
        'x-consul-index'        => '8',
        'x-consul-knownleader'  => 'true',
        'x-consul-lastcontact'  => '0'
      }
    end

    # Do not use ACL tokens for basic service tests
    before do
      Diplomat.configuration.acl_token = nil
    end

    describe 'GET' do
      it ':first' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url).and_return(OpenStruct.new(body: json))

        service = Diplomat::Service.new(faraday)

        expect(service.get('toast').Node).to eq('foo')
      end

      it ':all' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url).and_return(OpenStruct.new(body: json))

        service = Diplomat::Service.new(faraday)

        expect(service.get('toast', :all).size).to eq(2)
        expect(service.get('toast', :all).first.Node).to eq('foo')
      end
    end

    describe 'GET With Options' do
      it 'empty headers' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url).and_return(OpenStruct.new(body: json, headers: nil))

        service = Diplomat::Service.new(faraday)

        meta = {}
        s = service.get('toast', :first, {}, meta)
        expect(s.Node).to eq('foo')
        expect(meta.length).to eq(0)
      end

      it 'filled headers' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url).and_return(OpenStruct.new(body: json, headers: headers))

        service = Diplomat::Service.new(faraday)

        meta = {}
        s = service.get('toast', :first, {}, meta)
        expect(s.Node).to eq('foo')
        expect(meta[:index]).to eq('8')
        expect(meta[:knownleader]).to eq('true')
        expect(meta[:lastcontact]).to eq('0')
      end

      it 'index option' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url_with_indexoption).and_return(OpenStruct.new(body: json, headers: headers))

        service = Diplomat::Service.new(faraday)

        options = { index: '5' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'wait option' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url_with_waitoption).and_return(OpenStruct.new(body: json, headers: headers))

        service = Diplomat::Service.new(faraday)

        options = { wait: '6s' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'datacenter option' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url_with_datacenteroption).and_return(OpenStruct.new(body: json, headers: headers))

        service = Diplomat::Service.new(faraday)

        options = { dc: 'somedc' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'bad datacenter option' do
        faraday = double

        allow(faraday).to receive(:get)
          .with(key_url_with_datacenteroption)
          .and_raise(Faraday::ClientError.new({}, 500))

        service = Diplomat::Service.new(faraday)
        options = { dc: 'somedc' }
        expect { service.get('toast', :first, options) }.to raise_error(Diplomat::PathNotFound)
      end

      it 'tag option' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url_with_tagoption).and_return(OpenStruct.new(body: json, headers: headers))

        service = Diplomat::Service.new(faraday)
        options = { tag: 'sometag' }
        s = service.get('toast', :first, options)
        expect(s.Node).to eq('foo')
      end

      it 'all options' do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url_with_alloptions).and_return(OpenStruct.new(body: json, headers: headers))

        service = Diplomat::Service.new(faraday)

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

        faraday.stub(:get).and_return(OpenStruct.new(body: json))

        service = Diplomat::Service.new(faraday)
        expect(service.get_all.service1).to be_an(Array)
        expect(service.get_all.service2).to be_an(Array)
        expect(service.get_all.service1.first).to eq(service_one_tag)
        expect(service.get_all.service2.first).to eq(service_two_tag)
      end
      it 'lists all the services for the specified datacenter' do
        json = JSON.generate(body_all)

        faraday.stub(:get).with(services_url_with_datacenteroption).and_return(OpenStruct.new(body: json))

        options = { dc: 'somedc' }
        service = Diplomat::Service.new(faraday)
        expect(service.get_all(options).service1).to be_an(Array)
        expect(service.get_all(options).service2).to be_an(Array)
        expect(service.get_all(options).service1.first).to eq(service_one_tag)
        expect(service.get_all(options).service2.first).to eq(service_two_tag)
      end
    end

    describe 'Register service' do
      let(:register_service_url) { '/v1/agent/service/register' }
      let(:deregister_service_url) { '/v1/agent/service/deregister' }
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

        expect(faraday).to receive(:put).with(register_service_url, json_request) do
          OpenStruct.new(body: '', status: 200)
        end

        service = Diplomat::Service.new(faraday)
        s = service.register(service_definition)
        expect(s).to eq(true)
      end

      it 'can deregister a service' do
        url = "#{deregister_service_url}/#{service_definition[:name]}"
        expect(faraday).to receive(:put).with(url) do
          OpenStruct.new(body: '', status: 200)
        end
        service = Diplomat::Service.new(faraday)
        s = service.deregister(service_definition[:name])
        expect(s).to eq(true)
      end
    end

    describe 'Register external service' do
      let(:register_service_url) { '/v1/catalog/register' }
      let(:deregister_service_url) { '/v1/catalog/deregister' }

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

        expect(faraday).to receive(:put).with(register_service_url, json_request) do
          OpenStruct.new(body: '', status: 200)
        end

        service = Diplomat::Service.new(faraday)
        s = service.register_external(service_definition)
        expect(s).to eq(true)
      end

      it 'can deregister a service' do
        json_request = JSON.dump(deregister_definition)
        expect(faraday).to receive(:put).with(deregister_service_url, json_request) do
          OpenStruct.new(body: '', status: 200)
        end

        service = Diplomat::Service.new(faraday)
        s = service.deregister_external(deregister_definition)
        expect(s).to eq(true)
      end
    end

    describe '#maintenance' do
      let(:service_id) { 'TEST1' }
      let(:enable_url) { '/v1/agent/service/maintenance/TEST1?enable=true' }
      let(:disable_url) { '/v1/agent/service/maintenance/TEST1?enable=false' }
      let(:message_url) { enable_url + '&reason=My+Maintenance+Reason' }

      context 'when enabling maintenance' do
        let(:s) do
          proc do |reason|
            expect(faraday).to receive(:put).with(enable_url).and_return(OpenStruct.new(body: '', status: 200))
            service = Diplomat::Service.new(faraday)
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
          expect(faraday).to receive(:put).with(message_url).and_return(OpenStruct.new(body: '', status: 200))
          service = Diplomat::Service.new(faraday)
          s_message = service.maintenance(service_id, enable: 'true', reason: reason)
          expect(s_message).to eq(true)
        end
      end

      context 'when disabling maintenance' do
        let(:s) do
          proc do
            expect(faraday).to receive(:put).with(disable_url).and_return(OpenStruct.new(body: '', status: 200))
            service = Diplomat::Service.new(faraday)
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
    let(:acl_token) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f1' }

    describe 'GET' do
      let(:service_name) { 'toast' }

      before do
        allow(faraday).to receive(:get).and_return(OpenStruct.new(body: '{}'))
      end

      it 'token empty' do
        expect(faraday).to receive(:get).with("/v1/catalog/service/#{service_name}")
        Diplomat.configuration.acl_token = nil
        service = Diplomat::Service.new(faraday)

        service.get(service_name)
      end

      it 'token specified' do
        expect(faraday).to receive(:get).with("/v1/catalog/service/#{service_name}?token=#{acl_token}")
        Diplomat.configuration.acl_token = acl_token
        service = Diplomat::Service.new(faraday)

        service.get(service_name)
      end
    end

    describe 'GET_ALL' do
      before do
        allow(faraday).to receive(:get).and_return(OpenStruct.new(body: '{}'))
      end

      it 'token empty' do
        expect(faraday).to receive(:get).with('/v1/catalog/services')
        Diplomat.configuration.acl_token = nil
        service = Diplomat::Service.new(faraday)

        service.get_all
      end

      it 'token specified' do
        expect(faraday).to receive(:get).with("/v1/catalog/services?token=#{acl_token}")

        Diplomat.configuration.acl_token = acl_token
        service = Diplomat::Service.new(faraday)

        service.get_all
      end
    end
  end
end
