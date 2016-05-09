require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Service do

  let(:faraday) { fake }

  context "services" do
    let(:key) { "toast" }
    let(:key_url) { "/v1/catalog/service/#{key}" }
    let(:key_url_with_alloptions) { "/v1/catalog/service/#{key}?wait=5m&index=3&dc=somedc" }
    let(:key_url_with_indexoption) { "/v1/catalog/service/#{key}?index=5" }
    let(:key_url_with_waitoption) { "/v1/catalog/service/#{key}?wait=6s" }
    let(:key_url_with_datacenteroption) { "/v1/catalog/service/#{key}?dc=somedc" }
    let(:key_url_with_tagoption) { "/v1/catalog/service/#{key}?tag=sometag" }
    let(:services_url_with_datacenteroption) { "/v1/catalog/services?dc=somedc" }
    let(:body) {
      [
        {
          "Node"        => "foo",
          "Address"     => "10.1.10.12",
          "ServiceID"   => key,
          "ServiceName" => key,
          "ServiceTags" => ['sometag'],
          "ServicePort" => "70457"
        },
        {
          "Node"        => "bar",
          "Address"     => "10.1.10.13",
          "ServiceID"   => key,
          "ServiceName" => key,
          "ServiceTags" => ['sometag', 'anothertag'],
          "ServicePort" => "70457"
        }
      ]
    }
    let(:body_all) {
      {
        service1: ["tag one", "tag two", "tag three"],
        service2: ["tag four"]
      }
    }
    let(:headers) {
      {
        "x-consul-index"        => "8",
        "x-consul-knownleader"  => "true",
        "x-consul-lastcontact"  => "0"
      }
    }

    describe "GET" do
      it ":first" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json }))

        service = Diplomat::Service.new(faraday)

        expect(service.get("toast").Node).to eq("foo")
      end

      it ":all" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json }))

        service = Diplomat::Service.new(faraday)

        expect(service.get("toast", :all).size).to eq(2)
        expect(service.get("toast", :all)[0].Node).to eq("foo")
      end
    end

    describe "GET With Options" do
      it "empty headers" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json, headers: nil }))

        service = Diplomat::Service.new(faraday)

        meta = {}
        s = service.get("toast", :first, {}, meta)
        expect(s.Node).to eq("foo")
        expect(meta.length).to eq(0)
      end

      it "filled headers" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json, headers: headers }))

        service = Diplomat::Service.new(faraday)

        meta = {}
        s = service.get("toast", :first, {}, meta)
        expect(s.Node).to eq("foo")
        expect(meta[:index]).to eq("8")
        expect(meta[:knownleader]).to eq("true")
        expect(meta[:lastcontact]).to eq("0")
      end

      it "index option" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url_with_indexoption).and_return(OpenStruct.new({ body: json, headers: headers }))

        service = Diplomat::Service.new(faraday)

        options = { :index => "5" }
        s = service.get("toast", :first, options)
        expect(s.Node).to eq("foo")
      end

      it "wait option" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url_with_waitoption).and_return(OpenStruct.new({ body: json, headers: headers }))

        service = Diplomat::Service.new(faraday)

        options = { :wait => "6s" }
        s = service.get("toast", :first, options)
        expect(s.Node).to eq("foo")
      end

      it "datacenter option" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url_with_datacenteroption).and_return(OpenStruct.new({ body: json, headers: headers }))

        service = Diplomat::Service.new(faraday)

        options = { :dc => "somedc" }
        s = service.get("toast", :first, options)
        expect(s.Node).to eq("foo")
      end

      it "bad datacenter option" do
        faraday = double()

        allow(faraday).to receive(:get)
                            .with(key_url_with_datacenteroption)
                            .and_raise(
                              Faraday::ClientError.new({}, 500)
                            )

        Diplomat.configuration.acl_token = nil
        service = Diplomat::Service.new(faraday)
        options = { :dc => "somedc" }
        expect{ service.get("toast", :first, options) }.to raise_error(Diplomat::PathNotFound)
      end

      it "tag option" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url_with_tagoption).and_return(OpenStruct.new({ body: json, headers: headers }))

        service = Diplomat::Service.new(faraday)
        options = { :tag => "sometag" }
        s = service.get("toast", :first, options)
        expect(s.Node).to eq("foo")
      end

      it "all options" do
        json = JSON.generate(body)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(key_url_with_alloptions).and_return(OpenStruct.new({ body: json, headers: headers }))

        service = Diplomat::Service.new(faraday)

        options = { :wait => "5m", :index => "3", :dc => 'somedc' }
        s = service.get("toast", :first, options)
        expect(s.Node).to eq("foo")
      end
    end

    describe "GET ALL" do
      it "lists all the services for the default datacenter" do
        json = JSON.generate(body_all)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

        service = Diplomat::Service.new(faraday)
        expect(service.get_all.service1).to be_an(Array)
        expect(service.get_all.service2).to be_an(Array)
        expect(service.get_all.service1.first).to eq("tag one")
        expect(service.get_all.service2.first).to eq("tag four")
      end
      it "lists all the services for the specified datacenter" do
        json = JSON.generate(body_all)

        Diplomat.configuration.acl_token = nil
        faraday.stub(:get).with(services_url_with_datacenteroption).and_return(OpenStruct.new({ body: json }))

        options = { :dc => "somedc" }
        service = Diplomat::Service.new(faraday)
        expect(service.get_all(options).service1).to be_an(Array)
        expect(service.get_all(options).service2).to be_an(Array)
        expect(service.get_all(options).service1.first).to eq("tag one")
        expect(service.get_all(options).service2.first).to eq("tag four")
      end
    end

    describe "Register service" do
      let (:register_service_url) { '/v1/agent/service/register' }
      let (:deregister_service_url) { '/v1/agent/service/deregister' }

      let (:service_definition) do
        {
          name: 'test_service_definition',
          check: {
            script: 'echo "true"',
            interval: "1s"
          }
        }
      end

      it 'can register a service' do

        json_request = JSON.dump(service_definition)

        expect(faraday).to receive(:put).with(register_service_url, json_request) do
          OpenStruct.new({ body: '', status: 200 })
        end

        service = Diplomat::Service.new(faraday)
        s = service.register(service_definition)
        expect(s).to eq(true)
      end

      it 'can deregister a service' do
        url = "#{deregister_service_url}/#{service_definition[:name]}"
        expect(faraday).to receive(:get).with(url) do
          OpenStruct.new({ body: '', status: 200 })
        end
        service = Diplomat::Service.new(faraday)
        s = service.deregister(service_definition[:name])
        expect(s).to eq(true)
      end
    end

  end

end
