# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::Status do
  let(:faraday) { fake }

  context 'leader' do
    it 'GET' do
      json = JSON.generate('10.1.10.12:8300')

      faraday.stub(:get).and_return(OpenStruct.new(body: json))

      leader = Diplomat::Status.new(faraday)

      expect(leader.leader).to eq('10.1.10.12:8300')
    end
  end
  context 'peers' do
    it 'GET' do
      json = JSON.generate(
        [
          '10.1.10.12:8300',
          '10.1.10.11:8300',
          '10.1.10.10:8300'
        ]
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))

      peers = Diplomat::Status.new(faraday)

      expect(peers.peers).to eq(
        [
          '10.1.10.12:8300',
          '10.1.10.11:8300',
          '10.1.10.10:8300'
        ]
      )
    end
  end
end
