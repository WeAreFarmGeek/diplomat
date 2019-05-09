require 'spec_helper'

describe Diplomat::Role do
  context 'Consul 1.5+' do
    let(:key_url) { 'http://localhost:8500/v1/acl' }
    let(:id) { '4fcb8566-07b3-4deb-8c1b-393d31c16dd6' }
    let(:name) { 'test' }
    let(:read_body) do
      [
        {
          'ID' => id,
          'Name' => 'test',
          'Description' => 'Test role',
          'Hash' => 'WIDzFAz18+8f+V1auNnrWdXiyZTrDWtKnzL/7OXXvYM=',
          'CreateIndex' => 42,
          'ModifyIndex' => 4242,
          'Policies' => [
            { "ID": '783beef3-783f-f41f-7422-7087dc272765' },
            { "Name": 'node-read' }
          ],
          "ServiceIdentities": [
            { "ServiceName": 'web' },
            {
              "ServiceName": 'db',
              "Datacenters": [
                'dc1'
              ]
            }
          ]
        }
      ]
    end
    let(:list_body) do
      [
        read_body,
        {
          "ID": '5e52a099-4c90-c067-5478-980f06be9af5',
          "Name": 'node-read',
          "Description": '',
          "Policies": [
            {
              "ID": '783beef3-783f-f41f-7422-7087dc272765',
              "Name": 'node-read'
            }
          ],
          "Hash": 'K6AbfofgiZ1BEaKORBloZf7WPdg45J/PipHxQiBlK1U=',
          "CreateIndex": 50,
          "ModifyIndex": 50
        }
      ]
    end

    describe 'read' do
      it 'returns an existing ACL role if passing an UUID' do
        json = JSON.generate(read_body)

        url = key_url + '/role/' + id
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        role = Diplomat::Role.new
        role_info = role.read(id)

        expect(role_info.size).to eq(1)
        expect(role_info.first['Name']).to eq('test')
      end

      it 'returns an existing ACL role if passing a name' do
        json = JSON.generate(read_body)

        url = key_url + '/role/name/' + name
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        role = Diplomat::Role.new
        role_info = role.read(name)

        expect(role_info.size).to eq(1)
        expect(role_info.first['Name']).to eq('test')
      end

      it 'raises an error if ACL role name does not exist' do
        json = 'null'

        url = key_url + '/role/name/' + 'none'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 404))

        role = Diplomat::Role.new

        expect { role.read('none') }.to raise_error(Diplomat::RoleNotFound)
      end

      it 'raises an error if ACL role UUID does not exist' do
        json = 'null'

        url = key_url + '/role/' + '86f16056-1289-4ae2-bea0-8e1bf9128866'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 404))

        role = Diplomat::Role.new

        expect { role.read('86f16056-1289-4ae2-bea0-8e1bf9128866') }.to raise_error(Diplomat::RoleNotFound)
      end
    end

    describe 'list' do
      it 'returns all ACL roles' do
        json = JSON.generate(list_body)

        url = key_url + '/roles'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        role = Diplomat::Role.new
        list = role.list

        expect(list.size).to eq(2)
      end
    end

    describe 'update' do
      it 'returns the updated ACL role' do
        json = JSON.generate(read_body.first)

        url = key_url + '/role/' + id
        stub_request(:put, url).to_return(OpenStruct.new(body: json, status: 200))

        role = Diplomat::Role.new
        response = role.update(read_body.first)

        expect(response['ID']).to eq(read_body.first['ID'])
      end

      it 'fails if no ID is provided' do
        role = Diplomat::Role.new
        expect { role.update(Description: 'test', Name: 'test') }.to raise_error(Diplomat::IdParameterRequired)
      end

      it 'fails if no Name is provided' do
        role = Diplomat::Role.new
        expect { role.update(ID: 'test') }.to raise_error(Diplomat::NameParameterRequired)
      end
    end

    describe 'create' do
      it 'returns the ACL Role' do
        json = JSON.generate(read_body.first.tap { |h| h.delete('ID') })

        url = key_url + '/role'
        stub_request(:put, url)
          .with(body: json).to_return(OpenStruct.new(body: json, status: 200))

        role = Diplomat::Role.new
        response = role.create(read_body.first)

        expect(response['ID']).to eq(read_body.first['ID'])
      end
    end

    describe 'delete' do
      it 'returns true with 200 OK' do
        url = key_url + '/role/' + id
        stub_request(:delete, url).to_return(OpenStruct.new(body: "true\n", status: 200))

        role = Diplomat::Role.new
        response = role.delete(id)

        expect(response).to be true
      end
    end
  end
end
