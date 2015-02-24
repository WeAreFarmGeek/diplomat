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
    let(:valid_acl_token) { "f45cbd0b-5022-47ab-8640-4eaa7c1f40f1" }

    describe "#get" do
      context "ACLs NOT enabled" do
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
      end
      context "ACLs enabled, without valid_acl_token" do
        it "GET with ACLs enabled, no valid_acl_token" do
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64("Faraday::ResourceNotFound: the server responded with status 404"),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get("key")).to eq("Faraday::ResourceNotFound: the server responded with status 404")
        end
      end
      context "ACLs enabled, with valid_acl_token" do
        it "GET with ACLs enabled, valid_acl_token" do
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ body: json }))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get("key")).to eq("toast")
        end
      end
    end

    describe "#put" do
      context "ACLs NOT enabled" do
        it "PUT" do
          faraday.stub(:put).and_return(OpenStruct.new({ body: "true\n"}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params)).to eq(key_params)
        end
        it "PUT with CAS param" do
          options = {:cas => modify_index}
          faraday.stub(:put).and_return(OpenStruct.new({ body: "true\n"}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(key_params)
        end
      end
      context "ACLs enabled, without valid_acl_token" do
        it "PUT with ACLs enabled, no valid_acl_token" do
          faraday.stub(:put).and_return(OpenStruct.new({ body: "false\n" }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params)).to eq("false\n")
        end
        it "PUT with CAS param, without valid_acl_token" do
          options = {:cas => modify_index}
          faraday.stub(:put).and_return(OpenStruct.new({ body: "false\n"}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq("false\n")
        end
      end
      context "ACLs enabled, with valid_acl_token" do
        it "PUT with ACLs enabled, valid_acl_token" do
          faraday.stub(:put).and_return(OpenStruct.new({ body: "true\n"}))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)

          expect(kv.put(key, key_params)).to eq(key_params)
        end
        it "PUT with CAS param" do
          options = {:cas => modify_index}
          faraday.stub(:put).and_return(OpenStruct.new({ body: "true\n"}))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(key_params)
        end
      end
    end

    describe "#delete" do
      context "ACLs NOT enabled" do
        it "DELETE" do
          faraday.stub(:delete).and_return(OpenStruct.new({ status: 200}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.delete(key).status).to eq 200 
        end
      end
      context "ACLs enabled, without valid_acl_token" do
        it "DELETE" do
          faraday.stub(:delete).and_return(OpenStruct.new({ status: 403}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.delete(key).status).to eq 403 
        end
      end
      context "ACLs enabled, with valid_acl_token" do
        it "DELETE" do
          faraday.stub(:delete).and_return(OpenStruct.new({ status: 200}))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.delete(key).status).to eq 200
        end
      end
    end

    it "namespaces" do
      faraday.stub(:put).and_return(OpenStruct.new({ body: "true\n"}))
      kv = Diplomat::Kv.new(faraday)

      expect(kv.put("toast/#{key}", key_params)).to eq(key_params)
    end

  end

end
