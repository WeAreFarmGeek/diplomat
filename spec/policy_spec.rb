require 'spec_helper'

describe Diplomat::Policy do
  context 'Consul 1.4+' do
    let(:key_url) { 'http://localhost:8500/v1/acl' }
    let(:id) { '2c9e66bd-9b67-ef5b-34ac-38901e792646' }
    let(:read_body) do
      [
        {
          'ID' => id,
          'Name' => 'test',
          'Description' => 'Test policy',
          'Hash' => 'WIDzFAz18+8f+V1auNnrWdXiyZTrDWtKnzL/7OXXvYM=',
          'CreateIndex' => 42,
          'ModifyIndex' => 4242,
          'Rules' => {
            'node_prefix' => {
              '' => {
                'policy' => 'read'
              }
            }
          }
        }
      ]
    end
    let(:list_body) do
      [
        read_body,
        {
          'ID' => '00000000-0000-0000-0000-000000000001',
          'Name' => 'global-management',
          'Description' => 'Builtin Policy that grants unlimited access',
          'Datacenters' => nil,
          'Hash' => 'swIQt6up+s0cV4kePfJ2aRdKCLaQyykF4Hl1Nfdeumk=',
          'CreateIndex' => 4,
          'ModifyIndex' => 4
        }
      ]
    end

    describe 'read' do
      it 'returns an existing ACL policy' do
        json = JSON.generate(read_body)

        url = key_url + '/policy/' + id
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        policy = Diplomat::Policy.new
        policy_info = policy.read(id)

        expect(policy_info.size).to eq(1)
        expect(policy_info.first['Name']).to eq('test')
      end

      it 'raises an error if ACL policy does not exist' do
        json = 'null'

        url = key_url + '/policy/' + 'none'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 404))

        policy = Diplomat::Policy.new

        expect { policy.read('none') }.to raise_error(Diplomat::PolicyNotFound)
      end
    end

    describe 'list' do
      it 'returns all ACL policies' do
        json = JSON.generate(list_body)

        url = key_url + '/policies'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        policy = Diplomat::Policy.new
        list = policy.list

        expect(list.size).to eq(2)
      end
    end

    describe 'update' do
      it 'returns the updated ACL policy' do
        json = JSON.generate(read_body.first)

        url = key_url + '/policy/' + id
        stub_request(:put, url).to_return(OpenStruct.new(body: json, status: 200))

        policy = Diplomat::Policy.new
        response = policy.update(read_body.first)

        expect(response['ID']).to eq(read_body.first['ID'])
      end

      it 'fails if no ID is provided' do
        policy = Diplomat::Policy.new
        expect { policy.update(Description: 'test', Name: 'test') }.to raise_error(Diplomat::IdParameterRequired)
      end

      it 'fails if no Name is provided' do
        policy = Diplomat::Policy.new
        expect { policy.update(ID: 'test') }.to raise_error(Diplomat::NameParameterRequired)
      end
    end

    describe 'create' do
      it 'returns the ACL Policy' do
        json = JSON.generate(read_body.first.tap { |h| h.delete('ID') })

        url = key_url + '/policy'
        stub_request(:put, url)
          .with(body: json).to_return(OpenStruct.new(body: json, status: 200))

        policy = Diplomat::Policy.new
        response = policy.create(read_body.first)

        expect(response['ID']).to eq(read_body.first['ID'])
      end
    end

    describe 'delete' do
      it 'returns true with 200 OK' do
        url = key_url + '/policy/' + id
        stub_request(:delete, url).to_return(OpenStruct.new(body: "true\n", status: 200))

        policy = Diplomat::Policy.new
        response = policy.delete(id)

        expect(response).to be true
      end
    end
  end
end
