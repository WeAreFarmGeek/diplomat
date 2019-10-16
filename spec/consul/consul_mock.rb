require 'webmock/rspec'

module Consul
  module ConsulMock
    def find_absolute_path(name)
      File.expand_path("../resources/#{name}", __FILE__)
    end

    def read(name)
      File.read find_absolute_path(name)
    end

    def read_json(name)
      input = read(name)
      JSON.parse input
    end

    # rubocop:disable Metrics/ParameterLists
    def mock_path(path, file, port, http_method = :get, status = 200, _query_params = {})
      body = read(file)
      stub_request(http_method, %r{^http://localhost:#{port}/#{path}(?:\?.*)?$})
        .to_return(body: body, status: status)
      body
    end
    # rubocop:enable Metrics/ParameterLists

    def mock_consul_path(path)
      mock_path(path, "consul/#{path}.json", 8500, :get)
    end

    # rubocop:disable Metrics/MethodLength
    def mock_consul
      results = {}
      %w[v1/agent/self
         v1/agent/members
         v1/catalog/datacenters
         v1/catalog/services
         v1/health/service/service01
         v1/health/service/service02
         v1/health/service/service03
         v1/health/service/service04
         v1/health/state/any
         v1/status/leader].each do |path|
        results[path] = mock_consul_path path
      end
      results
    end
    # rubocop:enable Metrics/MethodLength

    def mock_json
      stub_request(:get, 'https://rubygems.org/api/v1/versions/consul-templaterb.json')
        .to_return(body: read_json('rubygems_org_consul_templaterb.json').to_json, status: 200)
    end
  end
end
