require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Health do

  let(:faraday) { fake }

  context "health" do

    it "node" do
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
                "CheckID": "service:redis",
                "Name": "Service 'redis' check",
                "Status": "passing",
                "Notes": "",
                "Output": "",
                "ServiceID": "redis",
                "ServiceName": "redis"
            }
        ]
EOF

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

      health = Diplomat::Health.new(faraday)

      expect(health.node("foobar")[0]["Node"]).to eq("foobar")
    end

    it "checks" do
      json = <<EOF
[
    {
        "Node": "foobar",
        "CheckID": "service:redis",
        "Name": "Service 'redis' check",
        "Status": "passing",
        "Notes": "",
        "Output": "",
        "ServiceID": "redis",
        "ServiceName": "redis"
    }
]
EOF

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

      health = Diplomat::Health.new(faraday)

      expect(health.checks("foobar")[0]["Node"]).to eq("foobar")
    end

    it "service" do
      json = <<EOF
[
    {
        "Node": {
            "Node": "foobar",
            "Address": "10.1.10.12"
        },
        "Service": {
            "ID": "redis",
            "Service": "redis",
            "Tags": null,
            "Port": 8000
        },
        "Checks": [
            {
                "Node": "foobar",
                "CheckID": "service:redis",
                "Name": "Service 'redis' check",
                "Status": "passing",
                "Notes": "",
                "Output": "",
                "ServiceID": "redis",
                "ServiceName": "redis"
            },
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
    }
]
EOF

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

      health = Diplomat::Health.new(faraday)

      expect(health.service("foobar")[0]["Node"]["Node"]).to eq("foobar")
    end

it "state" do
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
        "CheckID": "service:redis",
        "Name": "Service 'redis' check",
        "Status": "passing",
        "Notes": "",
        "Output": "",
        "ServiceID": "redis",
        "ServiceName": "redis"
    }
]
EOF

      faraday.stub(:get).and_return(OpenStruct.new({ body: json }))

      health = Diplomat::Health.new(faraday)

      expect(health.state("foobar")[0]["Node"]).to eq("foobar")
    end


  end

end
