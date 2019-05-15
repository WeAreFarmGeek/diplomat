require 'spec_helper'

describe Diplomat::Token do
  context 'Consul 1.5+' do
    let(:key_url) { 'http://localhost:8500/v1/acl' }
    let(:id) { 'a76289be-986c-98d7-3176-5f946da90d09' }
    let(:read_body) do
      [
        { 'AccessorID' => id,
          'CreateIndex' => 5,
          'CreateTime' => '2019-04-30T01:48:43.548395347Z',
          'Description' => 'Master Token',
          'Hash' => '4H7ICbDZ4j6AdxBPps0g3c8dGOg5QUg7BfxngwA4i+c=',
          'Local' => false,
          'ModifyIndex' => 5,
          'Policies' => [
            { 'ID' => '00000000-0000-0000-0000-000000000001', 'Name' => 'global-management' }
          ],
          'Roles' => [
            { 'ID' => 'e9804138-3b6f-494c-b566-2de8944e049f', 'Name' => 'read-only' }
          ],
          'SecretID' => 'changeme' }
      ]
    end
    let(:list_body) do
      [
        read_body,
        { 'AccessorID' => '00000000-0000-0000-0000-000000000002',
          'CreateIndex' => 6,
          'CreateTime' => '2019-04-30T01:48:43.548983509Z',
          'Description' => 'Anonymous Token',
          'Hash' => 'RNVFSWnfd5DUOuB8vplp+imivlIna3fKQVnkUHh21cA=',
          'Local' => false,
          'ModifyIndex' => 6,
          'Policies' => nil }
      ]
    end

    describe 'read' do
      it 'returns an existing ACL token' do
        json = JSON.generate(read_body)

        url = key_url + '/token/' + id
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        token = Diplomat::Token.new
        token_info = token.read(id)

        expect(token_info.size).to eq(1)
        expect(token_info.first['Description']).to eq('Master Token')
      end

      it 'raises an error if ACL token does not exist' do
        json = 'null'

        url = key_url + '/token/' + '99999999-9999-9999-9999-999999999999'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 403))

        token = Diplomat::Token.new

        expect { token.read('99999999-9999-9999-9999-999999999999') }.to raise_error(Diplomat::AclNotFound)
      end
    end

    describe 'list' do
      it 'returns all ACL tokens' do
        json = JSON.generate(list_body)

        url = key_url + '/tokens'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        token = Diplomat::Token.new
        list = token.list

        expect(list.size).to eq(2)
      end

      it 'returns the ACL tokens matching the policy UUID' do
        json = JSON.generate(list_body.first)

        url = key_url + '/tokens' + '?policy=00000000-0000-0000-0000-000000000001'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        token = Diplomat::Token.new
        list = token.list('00000000-0000-0000-0000-000000000001')

        expect(list.size).to eq(1)
      end
    end

    describe 'update' do
      it 'returns the updated ACL token details' do
        json = JSON.generate(read_body.first.merge('SecretID' => 'updated'))

        url = key_url + '/token/' + id
        stub_request(:put, url).to_return(OpenStruct.new(body: json, status: 200))

        token = Diplomat::Token.new
        response = token.update(read_body.first)

        expect(response['AccessorID']).to eq(read_body.first['AccessorID'])
        expect(response['SecretID']).to eq('updated')
      end

      it 'fails if no AccessorID is provided' do
        token = Diplomat::Token.new
        expect { token.update(Description: 'test', Policies: []) }.to raise_error(Diplomat::AccessorIdParameterRequired)
      end
    end

    describe 'create' do
      it 'returns the ACL token details' do
        json = JSON.generate(read_body.first)

        url = key_url + '/token'
        stub_request(:put, url)
          .to_return(OpenStruct.new(body: json, status: 200))

        token = Diplomat::Token.new
        response = token.create(read_body.first)

        expect(response['AccessorID']).to eq(read_body.first['AccessorID'])
        expect(response['SecretID']).to eq(read_body.first['SecretID'])
      end
    end

    describe 'delete' do
      it 'returns true with 200 OK' do
        url = key_url + '/token/' + id
        stub_request(:delete, url).to_return(OpenStruct.new(body: "true\n", status: 200))

        token = Diplomat::Token.new
        response = token.delete(id)

        expect(response).to be true
      end
    end
  end
end
