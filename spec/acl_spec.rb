require 'spec_helper'

describe Diplomat::Acl do
  context 'acls' do
    let(:key_url) { 'http://localhost:8500/v1/acl' }
    let(:id) { '8f246b77-f3e1-ff88-5b48-8ec93abf3e05' }
    let(:info_body) do
      [
        {
          'CreateIndex' => 3,
          'ModifyIndex' => 3,
          'ID' => id,
          'Name' => 'Client Token',
          'Type' => 'client',
          'Rules' => {
            'service' => {
              '' => {
                'policy' => 'write'
              }
            }
          }
        }
      ]
    end
    let(:list_body) do
      [
        info_body,
        {
          'CreateIndex' => 3,
          'ModifyIndex' => 3,
          'ID' => 'another-id',
          'Name' => 'Client Token bis',
          'Type' => 'client',
          'Rules' => {
            'service' => {
              '' => {
                'policy' => 'write'
              }
            }
          }
        }
      ]
    end

    describe 'info' do
      it 'returns existing acl' do
        json = JSON.generate(info_body)

        url = key_url + '/info/' + id
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new
        info = acl.info(id)

        expect(info.size).to eq(1)
        expect(info.first['Name']).to eq('Client Token')
      end

      it 'returns does not return acl' do
        json = 'null'

        url = key_url + '/info/' + 'none'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new

        expect { acl.info('none') }.to raise_error(Diplomat::AclNotFound)
      end
    end

    describe 'list' do
      it 'return all acls' do
        json = JSON.generate(list_body)

        url = key_url + '/list'
        stub_request(:get, url).to_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new
        list = acl.list

        expect(list.size).to eq(2)
      end
    end

    describe 'update' do
      it 'return the ID' do
        json = JSON.generate(info_body.first)

        url = key_url + '/update'
        stub_request(:put, url).to_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new
        response = acl.update(info_body.first)

        expect(response['ID']).to eq(info_body.first['ID'])
      end

      it 'fails if no ID is provided ' do
        acl = Diplomat::Acl.new
        expect { acl.update(Name: 'test') }.to raise_error(Diplomat::IdParameterRequired)
      end
    end

    describe 'create' do
      it 'return the ID' do
        json = JSON.generate(info_body.first)

        url = key_url + '/create'
        stub_request(:put, url)
          .with(body: json).to_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new
        response = acl.create(info_body.first)

        expect(response['ID']).to eq(info_body.first['ID'])
      end
    end

    describe 'destroy' do
      it 'return the ID' do
        url = key_url + '/destroy/' + id
        stub_request(:put, url).to_return(OpenStruct.new(body: "true\n", status: 200))

        acl = Diplomat::Acl.new
        response = acl.destroy(id)

        expect(response).to be true
      end
    end
  end
end
