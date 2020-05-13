# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::Autopilot do
  let(:faraday) { fake }

  context 'autopilot' do
    it 'gets the configuration' do
      json = JSON.generate(
        {
          'CleanupDeadServers' => true,
          'LastContactThreshold' => '200ms',
          'MaxTrailingLogs' => 250,
          'ServerStabilizationTime' => '10ms',
          'RedundancyZoneTag' => '',
          'DisableUpgradeMigration' => false,
          'UpgradeVersionTag' => '',
          'CreateIndex' => 4,
          'ModifyIndex' => 4
        }
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))

      autopilot = Diplomat::Autopilot.new(faraday)

      expect(autopilot.get_configuration['CleanupDeadServers']).to eq(true)
    end

    it 'gets the health' do
      json = JSON.generate(
        {
        'Healthy' => true,
        'FailureTolerance' => 0,
        'Servers' => [{
          'ID' => 'e349749b-3303-3ddf-959c-b5885a0e1f6e',
          'Name' => 'node1',
          'Address' => '127.0.0.1:8300',
          'SerfStatus' => 'alive',
          'Version' => '0.7.4',
          'Leader' => true,
          'LastContact' => '0s',
          'LastTerm' => 2,
          'LastIndex' => 46,
          'Healthy' => true,
          'Voter' => true,
          'StableSince' => '2017-03-06T22:07:51Z',
          
        }]
        }
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))

      autopilot = Diplomat::Autopilot.new(faraday)

      expect(autopilot.get_health['Healthy']).to eq(true)
    end
  end
end
