require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Node do

  let(:faraday) { fake }

  context 'services' do
    let(:key) { 'foobar' }
    let(:valid_acl_token) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f1' }
    let(:key_url) { "/v1/catalog/node/#{key}" }
    let(:key_url_with_acl) { "/v1/catalog/node/#{key}?token=#{valid_acl_token}" }
    let(:all_url) { '/v1/catalog/nodes' }
    let(:body_all) {
      [
        {
          'Address'     => '10.1.10.12',
          'Node'        => 'foo'
        },
        {

          'Address'     => '10.1.10.13',
          'Node'        => 'bar',
        }
      ]
    }
    let(:body) {
      {
        'Node' => {
          'Node' => 'foobar',
          'Address' => '10.1.10.12'
        },
        'Services' => {
          'consul' => {
            'ID' => 'consul',
            'Service' => 'consul',
            'Tags' => nil,
            'Port' => 8300
          },
          'redis' => {
            'ID' => 'redis',
            'Service' => 'redis',
            'Tags' => [
              'v1'
            ],
            'Port' => 8000
          }
        }
      }
    }
    let(:body_without_acl) {
      {
        'Node' => {
          'Node' => 'foobar',
          'Address' => '10.1.10.12'
        },
        'Services' => {
          'consul' => {
            'ID' => 'consul',
            'Service' => 'consul',
            'Tags' => nil,
            'Port' => 8300
          }
        }
      }
    }

    describe 'GET ALL' do
      it 'lists all the nodes' do
        json = JSON.generate(body_all)

        faraday.stub(:get).with(all_url).and_return(OpenStruct.new({ body: json }))

        node = Diplomat::Node.new(faraday)
        expect(node.get_all.size).to eq(2)
      end
    end

    describe 'GET' do
      context 'ACLs NOT enabled' do
        it 'node detail' do
          json = JSON.generate(body)

          Diplomat.configuration.acl_token = nil
          faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json }))

          node = Diplomat::Node.new(faraday)
          cn = node.get('foobar')
          expect(cn['Node'].length).to eq(2)
          expect(cn['Services'].length).to eq(2)
        end
      end
      context 'ACLs enabled, without valid_acl_token' do
        it 'node detail' do
          json = JSON.generate(body_without_acl)

          Diplomat.configuration.acl_token = nil
          faraday.stub(:get).with(key_url).and_return(OpenStruct.new({ body: json }))

          node = Diplomat::Node.new(faraday)
          cn = node.get('foobar')
          expect(cn['Node'].length).to eq(2)
          expect(cn['Services'].length).to eq(1)
        end
      end
      context 'ACLs enabled + with valid_acl_token' do
        it 'node detail' do
          json = JSON.generate(body)

          Diplomat.configuration.acl_token = valid_acl_token
          faraday.stub(:get).with(key_url_with_acl).and_return(OpenStruct.new({ body: json }))

          node = Diplomat::Node.new(faraday)
          cn = node.get('foobar')
          expect(cn['Node'].length).to eq(2)
          expect(cn['Services'].length).to eq(2)
        end
      end
    end
  end

end
