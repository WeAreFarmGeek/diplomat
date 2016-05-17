require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Maintenance do

  let(:faraday) { fake }
  let(:req) { fake }

  context "enabled?" do
    it "enabled" do
      json = <<EOF
      [
            {
                "Node": "foobar",
                "CheckID": "serfHealth",
                "Name": "Serf Health Status",
                "Status": "passing",
                "Notes": "",
                "Output": "",
                "ServiceID": "",
                "ServiceName": ""
            },
            {
                "Node": "foobar",
                "CheckID": "_node_maintenance",
                "Name": "Node Maintenance Mode",
                "Status": "critical",
                "Notes": "foo",
                "Output": "",
                "ServiceID": "",
                "ServiceName": "",
                "CreateIndex": 135459,
                "ModifyIndex": 135459
            }
        ]
EOF
      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(maintenance.enabled?("foobar")).to eq(true)
    end

    it "disabled" do
      json = <<EOF
      [
            {
                "Node": "foobar",
                "CheckID": "serfHealth",
                "Name": "Serf Health Status",
                "Status": "passing",
                "Notes": "",
                "Output": "",
                "ServiceID": "",
                "ServiceName": ""
            }
        ]
EOF
      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(maintenance.enabled?("foobar")).to eq(false)
    end
  end

  context "enable" do
    before do
      expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new({ body: "", status: 200}))
    end

    it "enables" do
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(req).to receive(:url).with('/v1/agent/maintenance?enable=true')
      expect(maintenance.enable(true)).to eq(true)
    end

    it "disables" do
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(req).to receive(:url).with('/v1/agent/maintenance?enable=false')
      expect(maintenance.enable(false)).to eq(true)
    end

    it "with reason" do
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(req).to receive(:url).with('/v1/agent/maintenance?enable=true&reason=foobar')
      expect(maintenance.enable(true, 'foobar')).to eq(true)
    end

    it "with dc" do
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(req).to receive(:url).with('/v1/agent/maintenance?enable=true&reason=foobar&dc=abc')
      expect(maintenance.enable(true, 'foobar', {:dc => 'abc'})).to eq(true)
    end
  end

  context "enable raises errors" do
    it "throw error unless 200" do
      expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new({ body: "", status: 500}))
      maintenance = Diplomat::Maintenance.new(faraday)
      expect(req).to receive(:url).with('/v1/agent/maintenance?enable=true')
      expect{ maintenance.enable(true) }.to raise_error(Diplomat::UnknownStatus, 'status 500')
    end
  end
end

