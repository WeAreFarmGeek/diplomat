require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Service do

  let(:faraday) { fake }

  context "services" do
    let(:key) { "toast" }
    let(:key_url) { "/v1/catalog/service/#{key}" }
    let(:body) {
      [
        {
          "Node"        => "foo",
          "Address"     => "10.1.10.12",
          "ServiceID"   => key,
          "ServiceName" => key,
          "ServiceTags" => nil,
          "ServicePort" => "70457"
        },
        {
          "Node"        => "bar",
          "Address"     => "10.1.10.13",
          "ServiceID"   => key,
          "ServiceName" => key,
          "ServiceTags" => nil,
          "ServicePort" => "70457"
        }
      ]
    }

    describe "GET" do
      it ":first" do
        json = JSON.generate(body)

        faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

        service = Diplomat::Service.new(faraday)

        expect(service.get("toast").Node).to eq("foo")
      end

      it ":all" do
        json = JSON.generate(body)

        faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

        service = Diplomat::Service.new(faraday)

        expect(service.get("toast", :all).size).to eq(2)
        expect(service.get("toast", :all)[0].Node).to eq("foo")
      end
    end

  end

end
