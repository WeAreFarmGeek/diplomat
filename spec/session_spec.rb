require 'spec_helper'
require 'json'
require 'base64'

UUID = "fc5ca01a-c317-39ea-05e8-221da00d3a12"

describe Diplomat::Session do
  let(:faraday) { fake }
  let(:single_object) { {"ID" => UUID}  }
  let(:collection_object) { [single_object] }
  let(:single_json) { JSON.generate(single_object) }
  let(:collection_json) {JSON.generate(collection_object)}
  
  context "session" do

    it "create" do
      faraday.stub(:put).and_return(OpenStruct.new({ body: single_json }))
      session = Diplomat::Session.new(faraday)
      expect(session.create({})).to eq(UUID)
    end

    it "destroy" do
      faraday.stub(:put).and_return(OpenStruct.new({ body: "true"}))
      session = Diplomat::Session.new(faraday)
      expect(session.destroy(UUID)).to eq("true")
    end

    it "list" do
      faraday.stub(:get).and_return(OpenStruct.new({body: collection_json}))
      sessions = Diplomat::Session.new(faraday)
      expect(sessions.list).to eql(collection_object)
    end

    it "renew" do
      faraday.stub(:put).and_return(OpenStruct.new({body: collection_json}))
      session = Diplomat::Session.new(faraday)
      expect(session.renew(UUID)).to eql(collection_object)
    end
  end
end