# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::Session do
  let(:faraday) { fake }
  let(:uuid) { 'fc5ca01a-c317-39ea-05e8-221da00d3a12' }
  let(:single_object) { { 'ID' => uuid } }
  let(:collection_object) { [single_object] }
  let(:single_json) { JSON.generate(single_object) }
  let(:collection_json) { JSON.generate(collection_object) }

  describe '#create' do
    let(:cs) do
      faraday.stub(:put).and_return(OpenStruct.new(body: single_json))
      session = Diplomat::Session.new(faraday)
      session.create({})
    end

    it 'should return the session ID created' do
      expect(cs).to eq(uuid)
    end

    it 'should create session with dc option' do
      faraday.stub(:put).and_return(OpenStruct.new(body: single_json))
      session = Diplomat::Session.new(faraday)
      options = { dc: 'some-dc' }
      expect(session.create({}, options)).to eq(uuid)
    end
  end

  describe '#destroy' do
    let(:cs) do
      faraday.stub(:put).and_return(OpenStruct.new(body: 'true'))
      session = Diplomat::Session.new(faraday)
      session.destroy(uuid)
    end

    it 'should return sucess or failure string' do
      expect(cs).to eq('true')
    end

    it 'should return a string' do
      expect(cs).to be_a_kind_of(String)
    end

    it 'should destroy session with dc option' do
      faraday.stub(:put).and_return(OpenStruct.new(body: 'true'))
      session = Diplomat::Session.new(faraday)
      options = { dc: 'some-dc' }
      expect(session.destroy(uuid, options)).to eq('true')
    end
  end

  describe '#list' do
    let(:cs) do
      faraday.stub(:get).and_return(OpenStruct.new(body: collection_json))
      sessions = Diplomat::Session.new(faraday)
      sessions.list
    end

    it 'should return the session IDs' do
      cs.each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end

    it 'should return an array' do
      expect(cs).to be_a_kind_of(Array)
    end

    it 'should return an array of OpenStruct objects' do
      cs.each do |resp|
        expect(resp).to be_a_kind_of(OpenStruct)
      end
    end

    it 'should list sessions with dc option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: collection_json))
      sessions = Diplomat::Session.new(faraday)
      options = { dc: 'some-dc' }
      sessions.list(options).each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end
  end

  describe '#renew' do
    let(:cs) do
      faraday.stub(:put).and_return(OpenStruct.new(body: collection_json))
      session = Diplomat::Session.new(faraday)
      session.renew(uuid)
    end

    it 'should return the renewed session IDs' do
      cs.each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end

    it 'should return an array' do
      expect(cs).to be_a_kind_of(Array)
    end

    it 'should return an array of OpenStruct objects' do
      cs.each do |resp|
        expect(resp).to be_a_kind_of(OpenStruct)
      end
    end

    it 'should renew session with dc option' do
      faraday.stub(:put).and_return(OpenStruct.new(body: collection_json))
      sessions = Diplomat::Session.new(faraday)
      options = { dc: 'some-dc' }
      sessions.renew(uuid, options).each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end
  end

  describe '#info' do
    let(:raw_return) do
      [
        {
          'LockDelay' => 1.5e+10,
          'Checks' => ['serfHealth'],
          'Node' => 'foobar',
          'ID' => 'fc5ca01a-c317-39ea-05e8-221da00d3a12',
          'CreateIndex' => 1_086_449
        }
      ]
    end
    let(:json) { JSON.generate(raw_return) }
    let(:cs) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      session = Diplomat::Session.new(faraday)
      session.info(uuid)
    end

    it 'should return info for the given session ID' do
      cs.each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end

    it 'should return an array' do
      expect(cs).to be_a_kind_of(Array)
    end

    it 'should return an array of OpenStruct objects' do
      cs.each do |resp|
        expect(resp).to be_a_kind_of(OpenStruct)
      end
    end

    it 'should return session info with dc option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: collection_json))
      sessions = Diplomat::Session.new(faraday)
      options = { dc: 'some-dc' }
      sessions.info(uuid, options).each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end
  end

  describe '#node' do
    let(:raw_return) do
      [
        {
          'LockDelay' => 1.5e+10,
          'Checks' => ['serfHealth'],
          'Node' => 'foobar',
          'ID' => 'fc5ca01a-c317-39ea-05e8-221da00d3a12',
          'CreateIndex' => 1_086_449
        }
      ]
    end
    let(:json) { JSON.generate(raw_return) }
    let(:node) { 'foobar' }
    let(:cs) do
      faraday.stub(:get).and_return(OpenStruct.new(body: json))
      session = Diplomat::Session.new(faraday)
      session.node(node)
    end

    it 'should return the sessions info for the node' do
      cs.each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end

    it 'should return an array' do
      expect(cs).to be_a_kind_of(Array)
    end

    it 'should return an array of OpenStruct objects' do
      cs.each do |resp|
        expect(resp).to be_a_kind_of(OpenStruct)
      end
    end

    it 'should return session info for the node with dc option' do
      faraday.stub(:get).and_return(OpenStruct.new(body: collection_json))
      sessions = Diplomat::Session.new(faraday)
      options = { dc: 'some-dc' }
      sessions.node(node, options).each do |resp|
        expect(resp['ID']).to eql(uuid)
      end
    end
  end
end
