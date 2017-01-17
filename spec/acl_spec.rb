require 'spec_helper'

describe Diplomat::Acl do
  let(:faraday) { fake }

  context 'acls' do
    let(:key_url) { '/v1/acl' }
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
        expect(faraday).to receive(:get).with(/#{url}/).and_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new(faraday)
        info = acl.info(id)

        expect(info.size).to eq(1)
        expect(info.first['Name']).to eq('Client Token')
      end

      it 'returns does not return acl' do
        json = 'null'

        url = key_url + '/info/' + 'none'
        expect(faraday).to receive(:get).with(/#{url}/).and_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new(faraday)

        expect { acl.info('none') }.to raise_error(Diplomat::AclNotFound)
      end
    end

    describe 'list' do
      it 'return all acls' do
        json = JSON.generate(list_body)

        url = key_url + '/list'
        expect(faraday).to receive(:get).with(/#{url}/).and_return(OpenStruct.new(body: json, status: 200))

        acl = Diplomat::Acl.new(faraday)
        list = acl.list

        expect(list.size).to eq(2)
      end
    end

    describe 'update' do
      it 'return the ID' do
        json = JSON.generate(info_body.first)

        url = key_url + '/update'
        req = fake
        expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new(body: json, status: 200))
        expect(req).to receive(:url).with(/#{url}/)

        acl = Diplomat::Acl.new(faraday)
        response = acl.update(info_body.first)

        expect(response['ID']).to eq(info_body.first['ID'])
      end

      it 'fails if no ID is provided ' do
        acl = Diplomat::Acl.new(faraday)
        expect { acl.update(Name: 'test') }.to raise_error(Diplomat::IdParameterRequired)
      end
    end

    describe 'create' do
      it 'return the ID' do
        json = JSON.generate(info_body.first)

        url = key_url + '/create'
        req = fake
        expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new(body: json, status: 200))
        expect(req).to receive(:url).with(/#{url}/)

        acl = Diplomat::Acl.new(faraday)
        response = acl.create(info_body.first)

        expect(response['ID']).to eq(info_body.first['ID'])
      end
    end

    describe 'destroy' do
      it 'return the ID' do
        url = key_url + '/destroy/' + id
        expect(faraday).to receive(:put).with(/#{url}/).and_return(OpenStruct.new(body: 'true', status: 200))
        acl = Diplomat::Acl.new(faraday)
        response = acl.destroy(id)

        expect(response).to be true
      end
    end
  end
end
