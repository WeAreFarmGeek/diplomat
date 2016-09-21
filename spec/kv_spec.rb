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
      context "Datacenter filter" do
        it "GET" do
          faraday.double()
          kv = Diplomat::Kv.new(faraday)
          expect(faraday).to receive(:get)
                              .with(/dc=bar/)
                              .and_return(OpenStruct.new({ status: 200, body: JSON.generate([]) }))
          kv.get('foo', dc: 'bar')
        end
      end

      context "ACLs NOT enabled, recurse option ON" do
        let(:json) { JSON.generate([
          {
            "Key"   => key + 'dewfr',
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          },
          {
            "Key"   => key,
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          },
          {
            "Key"   => key + 'iamnil',
            "Value" => nil,
            "Flags" => 0
          }])
        }

        it "GET" do
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, recurse: true)).to eql([
            { key: key + 'dewfr', value: "toast" },
            { key: key, value: "toast" }
          ])
        end
        it "GET with nil values" do
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, recurse: true, nil_values: true )).to eql([
            { key: key + 'dewfr', value: "toast" },
            { key: key, value: "toast" },
            { key: key + 'iamnil', value: nil }
          ])
        end
      end
      context "ACLs NOT enabled, keys option ON" do
        let(:json) { JSON.generate([ key, key + "ring", key + "tar" ]) }
        it "GET" do
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, keys: true)).to eql([ key, key + "ring", key + "tar" ])
        end
      end

      context "ACLs NOT enabled, decode_values option ON" do
        let(:json) { JSON.generate([
          {
            "Key"   => key + 'dewfr',
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          },
          {
            "Key"   => key,
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          },
          {
            "Key"   => key + 'iamnil',
            "Value" => nil,
            "Flags" => 0
          }])
        }
        it "GET" do
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, decode_values: true)).to include({"Key" => key, "Value" => key_params, "Flags" => 0})
        end
      end

      context "ACLs NOT enabled, recurse option ON with transformation" do
        let(:number) { 1 }
        let(:string) { "x" }
        let(:hash) { "{\"x\": 1}" }
        let(:json) { JSON.generate([
          {
            "Key"   => key + 'number',
            "Value" => Base64.encode64(number.to_s),
            "Flags" => 0
          },
          {
            "Key"   => key + 'string',
            "Value" => Base64.encode64("\"#{string}\""),
            "Flags" => 0
          },
          {
            "Key"   => key + 'hash',
            "Value" => Base64.encode64(hash),
            "Flags" => 0
          }])
        }

        it "GET" do
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, recurse: true, transformation: Proc.new{|x| JSON.parse("[#{x}]")[0]} )).to eql([
            { key: key + 'number', value: number },
            { key: key + 'string', value: string },
            { key: key + 'hash', value: {"x" => 1} },
          ])
        end
      end
      context "ACLs NOT enabled" do
        it "GET" do
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key)).to eq("toast")
        end
        it "GET with consistency param" do
          options = {:consistency => "consistent"}
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get("key", options)).to eq("toast")
        end
      end
      context "ACLs enabled, without valid_acl_token" do
        it "GET with ACLs enabled, no valid_acl_token" do
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64("Faraday::ResourceNotFound: the server responded with status 404"),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key)).to eq("Faraday::ResourceNotFound: the server responded with status 404")
        end
        it "GET with consistency param, without valid_acl_token" do
          options = {:consistency => "consistent"}
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64("Faraday::ResourceNotFound: the server responded with status 404"),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get("key", options)).to eq("Faraday::ResourceNotFound: the server responded with status 404")
        end
      end
      context "ACLs enabled, with valid_acl_token" do
        it "GET with ACLs enabled, valid_acl_token" do
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key)).to eq("toast")
        end
        it "GET with consistency param, with valid_acl_token" do
          options = {:consistency => "consistent"}
          json = JSON.generate([{
            "Key"   => key,
            "Value" => Base64.encode64(key_params),
            "Flags" => 0
          }])
          faraday.stub(:get).and_return(OpenStruct.new({ status: 200, body: json }))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get("key", options)).to eq("toast")
        end
      end
    end

    describe "#put" do
      context "ACLs NOT enabled" do
        it "PUT" do
          faraday.stub(:put).and_return(OpenStruct.new({ status: 200, body: "true"}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params)).to eq(true)
          expect(kv.value).to eq(key_params)
        end
        it "PUT with CAS param" do
          options = {:cas => modify_index}
          faraday.stub(:put).and_return(OpenStruct.new({ status: 200, body: "true"}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(true)
          expect(kv.value).to eq(key_params)
        end
      end
      context "ACLs enabled, without valid_acl_token" do
        it "PUT with ACLs enabled, no valid_acl_token" do
          faraday.stub(:put).and_return(OpenStruct.new({ status: 200, body: "false" }))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params)).to eq(false)
        end
        it "PUT with CAS param, without valid_acl_token" do
          options = {:cas => modify_index}
          faraday.stub(:put).and_return(OpenStruct.new({ status: 200, body: "false"}))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(false)
        end
      end
      context "ACLs enabled, with valid_acl_token" do
        it "PUT with ACLs enabled, valid_acl_token" do
          faraday.stub(:put).and_return(OpenStruct.new({ status: 200, body: "true"}))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)

          expect(kv.put(key, key_params)).to eq(true)
          expect(kv.value).to eq(key_params)
        end
        it "PUT with CAS param" do
          options = {:cas => modify_index}
          faraday.stub(:put).and_return(OpenStruct.new({ status: 200, body: "true"}))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(true)
          expect(kv.value).to eq(key_params)
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

      context "ACLs NOT enabled, recurse option ON" do
        it "DELETE" do
          faraday.double()
          expect(faraday).to receive(:delete)
                              .with(/recurse/)
                              .and_return(OpenStruct.new({ status: 200}))

          kv = Diplomat::Kv.new(faraday)
          expect(kv.delete(key, :recurse => true).status).to eq 200
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
      faraday.stub(:put).and_return(OpenStruct.new({ status: 200, body: "true"}))
      kv = Diplomat::Kv.new(faraday)

      expect(kv.put("toast/#{key}", key_params)).to eq(true)
      expect(kv.value).to eq(key_params)
    end

  end

end
