require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Check do

  let(:faraday) { fake }

  context "check" do

    it "checks" do
      json = JSON.generate(
              {
                "service:redis"=> {
                    "Node"=>"foobar",
                    "CheckID"=>"service:redis",
                    "Name"=>"Service 'redis' check",
                    "Status"=>"passing",
                    "Notes"=>"",
                    "Output"=>"",
                    "ServiceID"=>"redis",
                    "ServiceName"=>"redis"}
              }
      )

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

      check = Diplomat::Check.new(faraday)

      expect(check.checks["service:redis"]["Node"]).to eq("foobar")
    end

    it "register" do
      faraday.stub(:put).and_return(OpenStruct.new({ body: '', status: 200 }))
      check = Diplomat::Check.new(faraday)
      expect(check.register("foobar-1", "Foobar", "Foobar test", "/script/test", "10s", "15s")).to eq(200)
    end

    it "deregister" do
      faraday.stub(:get).and_return(OpenStruct.new({ body: '', status: 200 }))
      check = Diplomat::Check.new(faraday)
      expect(check.deregister("foobar-1")).to eq(200)
    end

    it "pass" do
      faraday.stub(:get).and_return(OpenStruct.new({ body: '', status: 200 }))
      check = Diplomat::Check.new(faraday)
      expect(check.pass("foobar-1")).to eq(200)
    end

    it "warn" do
      faraday.stub(:get).and_return(OpenStruct.new({ body: '', status: 200 }))
      check = Diplomat::Check.new(faraday)
      expect(check.warn("foobar-1")).to eq(200)
    end

    it "fail" do
      faraday.stub(:get).and_return(OpenStruct.new({ body: '', status: 200 }))
      check = Diplomat::Check.new(faraday)
      expect(check.fail("foobar-1")).to eq(200)
    end

  end

end
