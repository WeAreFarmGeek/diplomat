require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Kv do

  let(:faraday) { fake }

  context "keys" do
    let(:key) { "key" }
    let(:key_url) { "/v1/kv/#{key}" }
    let(:key_params) { "toast" }
    let(:modify_index) { 99 }

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
      faraday.stub(:put).with(key_url, key_params).and_return(OpenStruct.new({ body: "true\n"}))
      kv = Diplomat::Kv.new(faraday)

      expect(kv.put(key, key_params)).to eq(key_params)
    end

    it "cas PUT" do
      options = {:cas => modify_index}
      url = "#{key_url}?cas=#{modify_index}"
      faraday.stub(:put).with(url, key_params).and_return(OpenStruct.new({ body: "true\n"}))

      kv = Diplomat::Kv.new(faraday)
      expect(kv.put(key, key_params, options)).to eq(key_params)
    end

    it "namespaces" do
      faraday.stub(:put).and_return(OpenStruct.new({ body: "true\n"}))
      kv = Diplomat::Kv.new(faraday)

      expect(kv.put("toast/#{key}", key_params)).to eq(key_params)
    end

  end

end
