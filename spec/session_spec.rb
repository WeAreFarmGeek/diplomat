require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Session do

  let(:faraday) { fake }

  context "session" do

    it "create" do
      json = JSON.generate(
        {"ID" => "fc5ca01a-c317-39ea-05e8-221da00d3a12"}
      )

      faraday.stub(:put).and_return(OpenStruct.new({ body: json }))

      session = Diplomat::Session.new(faraday)

      expect(session.create({})).to eq("fc5ca01a-c317-39ea-05e8-221da00d3a12")
    end

    it "destroy" do

      faraday.stub(:put).and_return(OpenStruct.new({ body: "true"}))
      session = Diplomat::Session.new(faraday)

      expect(session.destroy("fc5ca01a-c317-39ea-05e8-221da00d3a12")).to eq("true")
    end

    it "list" do
      json = JSON.generate(
        [{"ID" => "fc5ca01a-c317-39ea-05e8-221da00d3a12"}]
      )

      faraday.stub(:get).and_return(OpenStruct.new({body: json}))
      sessions = Diplomat::Session.new(faraday)
      expect(sessions.list[0]['ID']).to eq("fc5ca01a-c317-39ea-05e8-221da00d3a12")
    end

    it "renew" do
      json = JSON.generate(
        [{"ID" => "fc5ca01a-c317-39ea-05e8-221da00d3a12"}]
      )

      faraday.stub(:put).and_return(OpenStruct.new({body: json}))
      session = Diplomat::Session.new(faraday)
      expect(session.renew('fc5ca01a-c317-39ea-05e8-221da00d3a12')).to eql([{"ID" => "fc5ca01a-c317-39ea-05e8-221da00d3a12"}])
    end
    
  end

end