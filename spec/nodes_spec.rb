require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Nodes do

  let(:faraday) { fake }

  context "nodes" do

    it "GET" do
      json = JSON.generate(
      	[{
          "Node" => "baz",
          "Address" => "10.1.10.11"
         },
         {
          "Node" => "foobar",
          "Address" => "10.1.10.12"
         }]
      )

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

      nodes = Diplomat::Nodes.new(faraday)

      expect(nodes.get.first["Node"]).to eq("baz")
      expect(nodes.get.first["Address"]).to eq("10.1.10.11")
    end

  end

end
