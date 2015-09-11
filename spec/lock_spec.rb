require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Lock do
  let(:faraday) { fake }

  context 'lock' do
    it 'acquire' do
      faraday.stub(:put).and_return(OpenStruct.new(:body => 'true'))
      lock = Diplomat::Lock.new(faraday)
      expect(lock.acquire('fc5ca01a-c317-39ea-05e8-221da00d3a12', '/lock/key')).to eq(true)
    end

    it 'wait_to_acquire' do
      faraday.stub(:put).and_return(OpenStruct.new(:body => 'true'))
      lock = Diplomat::Lock.new(faraday)
      expect(lock.wait_to_acquire('fc5ca01a-c317-39ea-05e8-221da00d3a12', '/lock/key', 2)).to eq(true)
    end

    it 'release' do
      faraday.stub(:put).and_return(OpenStruct.new(:body => 'true'))
      lock = Diplomat::Lock.new(faraday)
      expect(lock.release('fc5ca01a-c317-39ea-05e8-221da00d3a12', '/lock/key')).to eq('true')
    end
  end
end
