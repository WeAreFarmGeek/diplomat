require 'spec_helper'
require 'json'

describe Diplomat::PreparedQuery do

  let(:faraday) { fake }

  context "pqueries" do
    let(:key_url) { "/v1/query" }

    let(:id) { "8f246b77-f3e1-ff88-5b48-8ec93abf3e05" }

    let(:info_body) {
      [
        {
          "ID" => id,
          "Name" => "",
          "Template" => {
            "Type" => "name_prefix_match"
          },
          "Service" => {
            "Service" => "${name.full}",
            "Failover" => {
              "NearestN" => 3
            },
          }
        }
      ]
    }
    let(:list_body) {
      [
        info_body.first,
        {
          "ID" => "7f62f110-30b1-b29d-c693-e3ec2c9e8e37",
          "Name" => "my-query",
          "Token" => "",
          "Service" => {
            "Service" => "redis",
            "Failover" => {
              "NearestN" => 3,
              "Datacenters" => ["dc1", "dc2"]
            },
            "Near" => "node1",
            "OnlyPassing" => false,
            "Tags" => ["primary", "!experimental"]
          },
          "DNS" => {
            "TTL" => "10s"
          }
        }
      ]
    }

    describe "info" do
      it "returns existing prepared query" do
        json = JSON.generate(info_body)

        url = key_url
        expect(faraday).to receive(:get).with(/#{url}/).and_return(OpenStruct.new({ body: json, status: 200}))

        pquery = Diplomat::PreparedQuery.new(faraday)
        info = pquery.info('')

        expect(info["Name"]).to eq("")
      end

      it "returns does not return prepared query" do
        json = '[]'

        url = key_url
        expect(faraday).to receive(:get).with(/#{url}/).and_return(OpenStruct.new({ body: json, status: 200}))

        pquery = Diplomat::PreparedQuery.new(faraday)

        expect { pquery.info('none') }.to raise_error(Diplomat::PreparedQueryNotFound)
      end
    end

    describe "list" do
      it "return all prepared queries" do
        json = JSON.generate(list_body)

        url = key_url
        expect(faraday).to receive(:get).with(/#{url}/).and_return(OpenStruct.new({ body: json, status: 200}))

        pquery = Diplomat::PreparedQuery.new(faraday)
        list = pquery.list

        expect(list.size).to eq(2)
      end
    end

    describe "update" do
      it "return status" do
        json = JSON.generate(list_body)

        url = key_url
        req = fake
        expect(faraday).to receive(:get).with(/#{url}/).and_return(OpenStruct.new({ body: json, status: 200}))
        expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new({ status: 200}))
        expect(req).to receive(:url).with(/#{url}\/#{id}/)

        pquery = Diplomat::PreparedQuery.new(faraday)
        response = pquery.update("", json)

        expect(response).to be true
      end
    end

    describe "create" do
      it "returns an ID" do
        json = JSON.generate(info_body.reject{|key, _| key == 'ID'}) # Delete the ID key, not authorized in create calls

        url = key_url
        req = fake
        expect(faraday).to receive(:post).and_yield(req).and_return(OpenStruct.new({ body: "{ \"ID\":\"#{id}\" }", status: 200}))
        expect(req).to receive(:url).with(/#{url}/)

        pquery = Diplomat::PreparedQuery.new(faraday)
        response = pquery.create(json)

        expect(response['ID']).to eq(id)
      end
    end

  end
end
