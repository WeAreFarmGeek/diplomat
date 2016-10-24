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

    it "node with dc option" do
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

      options = { dc: 'some-dc' }

      expect(health.node("foobar", options: options)[0]["Node"]).to eq("foobar")
    end

    it "checks with dc option" do
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

      options = { dc: 'some-dc' }

      expect(health.checks("foobar", options: options)[0]["Node"]).to eq("foobar")
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

    it "service with dc options" do
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

      options = { dc: 'some-dc' }

      expect(health.service("foobar", options: options)[0]["Node"]["Node"]).to eq("foobar")
    end

    it "service with tag options" do
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
            "Tags": ["v1"],
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

      options = { tag: 'v1' }

      expect(health.service("foobar", options: options)[0]["Node"]["Node"]).to eq("foobar")
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

    it "state with dc options" do
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

      options = { dc: 'some-dc' }

      expect(health.state("foobar", options: options)[0]["Node"]).to eq("foobar")
    end

  end

end
