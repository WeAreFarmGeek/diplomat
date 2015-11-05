require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Node do

  let(:faraday) { fake }

  context "services" do
    let(:key) { "foobar" }
    let(:key_url) { "/v1/catalog/node/#{key}" }
    let(:all_url) { "/v1/catalog/nodes" }
    let(:body_all) {
      [
        {
          "Address"     => "10.1.10.12",
          "Node"        => "foo"
        },
        {

          "Address"     => "10.1.10.13",
          "Node"        => "bar",
        }
      ]
    }
    let(:body) {
      {
        "Node" => {
          "Node" => "foobar",
          "Address" => "10.1.10.12"
        },
        "Services" => {
          "consul" => {
            "ID" => "consul",
            "Service" => "consul",
            "Tags" => nil,
            "Port" => 8300
          },
          "redis" => {
            "ID" => "redis",
            "Service" => "redis",
            "Tags" => [
              "v1"
            ],
            "Port" => 8000
          }
        }
      }
    }

    describe "GET ALL" do
      it "lists all the nodes" do
        json = JSON.generate(body_all)

        faraday.stub(:get).with(all_url).and_return(OpenStruct.new({ body: json }))

        node = Diplomat::Node.new(faraday)
        expect(node.get_all.size).to eq(2)
      end
    end

    describe "GET" do
      it "gets a node" do
        json = JSON.generate(body)

        faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json }))

        node = Diplomat::Node.new(faraday)

        cn = node.get("foobar")
        expect(cn["Node"].length).to eq(2)
      end
    end

  end

end
