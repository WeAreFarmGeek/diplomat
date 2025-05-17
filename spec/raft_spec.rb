# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::RaftOperator do
  let(:faraday) { fake }

  context 'raft configuration' do
    it 'gets the configuration' do
      json = JSON.generate(
        {
          'Servers' => [
            {
              'ID' => 'cacccbd1-4e97-40ec-917c-ebe5d8defcef',
              'Node' => 'CZ21256677DL',
              'Address' => '35.198.84.235:8300',
              'Leader' => true,
              'ProtocolVersion' => '3',
              'Voter' => true,
              'LastIndex' => 575_393_502
            },
            {
              'ID' => '01467a17-0e7b-4b16-8fd2-b53203531756',
              'Node' => 'CZ21209236DL',
              'Address' => '10.146.103.89:8300',
              'Leader' => false,
              'ProtocolVersion' => '3',
              'Voter' => true,
              'LastIndex' => 567_557_614
            },
            {
              'ID' => '8010b6c0-930d-442d-a15a-8082f573b768',
              'Node' => 'CZ21833778DL',
              'Address' => '145.109.51.4:8300',
              'Leader' => false,
              'ProtocolVersion' => '3',
              'Voter' => true,
              'LastIndex' => 521_866_110
            }
          ],
          'Index' => 0
        }
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))

      raft_operator = Diplomat::RaftOperator.new(faraday)

      expect(raft_operator.get_configuration['Servers'].length).to eq(3)
      expect(raft_operator.get_configuration['Servers'][0]['Leader']).to eq(true)
      expect(raft_operator.get_configuration['Servers'][1]['Leader']).to eq(false)
      expect(raft_operator.get_configuration['Servers'][2]['Leader']).to eq(false)
      expect(raft_operator.get_configuration['Index']).to eq(0)
    end

    it 'transfer leader' do
      json = JSON.generate(
        {
          'Success' => true
        }
      )

      faraday.stub(:post).and_return(OpenStruct.new(body: json))

      raft_operator = Diplomat::RaftOperator.new(faraday)

      expect(raft_operator.transfer_leader['Success']).to eq(true)
    end
  end
end
