require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Kv do

  let(:faraday) { fake }

  context "keys" do
    let(:key) { "key" }
    let(:key_url) { "/v1/kv/#{key}" }
    let(:key_params) { "toast" }

    it "GET" do
      json = JSON.generate([{
        "Key"   => key,
        "Value" => Base64.encode64(key_params),
        "Flags" => 0
      }])

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

      kv = Diplomat::Kv.new(faraday)

      expect(kv.get("key")).to eq("toast")
    end

    it "PUT" do

      json = JSON.generate([{
        "Key"   => key,
        "Value" => Base64.encode64(key_params),
        "Flags" => 0
      }])

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))
      faraday.stub(:put).and_return(OpenStruct.new({ body: json }))
      kv = Diplomat::Kv.new(faraday)

      expect(kv.put(key, key_params)).to eq(key_params)
    end

    it "namespaces" do
      json = JSON.generate([{
        "Key"   => key,
        "Value" => Base64.encode64(key_params),
        "Flags" => 0
      }])

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))
      faraday.stub(:put).and_return(OpenStruct.new({ body: json }))
      kv = Diplomat::Kv.new(faraday)

      expect(kv.put("toast/#{key}", key_params)).to eq(key_params)
    end

  end

end
