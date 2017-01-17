require 'spec_helper'

describe Diplomat::Members do
  let(:faraday) { fake }

  context 'member' do
    it 'GET' do
      json = JSON.generate(
        [{
          'Name' => 'foobar',
          'Addr' => '10.1.10.12',
          'Port' => 8301,
          'Tags' => {
            'bootstrap' => '1',
            'dc' => 'dc1',
            'port' => 8300,
            'role' => 'consul'
          },
          'Status' => 1,
          'ProtocolMin' => 1,
          'ProtocolMax' => 2,
          'ProtocolCur' => 2,
          'DelegateMin' => 1,
          'DelegateMax' => 3,
          'DelegateCur' => 3
        }]
      )

      faraday.stub(:get).and_return(OpenStruct.new(body: json))

      members = Diplomat::Members.new(faraday)

      expect(members.get[0]['Name']).to eq('foobar')
    end
  end
end
