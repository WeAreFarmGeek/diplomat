# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::Kv do
  let(:faraday) { fake }
  let(:req) { fake }

  context 'keys' do
    let(:key) { 'key' }
    let(:key_url) { "/v1/kv/#{key}" }
    let(:key_params) { 'toast' }
    let(:modify_index) { 99 }
    let(:valid_acl_token) { 'f45cbd0b-5022-47ab-8640-4eaa7c1f40f1' }

    describe '#get' do
      context 'Datacenter filter' do
        it 'GET' do
          kv = Diplomat::Kv.new
          stub_request(:get, 'http://localhost:8500/v1/kv/foo?dc=bar')
            .to_return(OpenStruct.new(status: 200, body: JSON.generate([])))
          kv.get('foo', dc: 'bar')
        end
      end

      context 'ACLs NOT enabled, recurse option ON' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key + 'dewfr',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key,
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key + 'iamnil',
                'Value' => nil,
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, recurse: true)).to eql(
            [
              { key: key + 'dewfr', value: 'toast' },
              { key: key, value: 'toast' }
            ]
          )
        end

        it 'GET with nil values' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, recurse: true, nil_values: true)).to eql(
            [
              { key: key + 'dewfr', value: 'toast' },
              { key: key, value: 'toast' },
              { key: key + 'iamnil', value: nil }
            ]
          )
        end
      end

      context 'ACLs NOT enabled, recurse option ON, blocking' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key + 'dewfr',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key,
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key + 'iamnil',
                'Value' => nil,
                'Flags' => 0
              }
            ]
          )
        end
        let(:headers) { JSON.generate('x-consul-index' => '12345') }

        it 'GET' do
          faraday.stub(:get).and_return(OpenStruct.new(headers: headers, status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          allow(kv).to receive_message_chain(:raw, :headers).and_return('x-consul-index' => '12345')
          expect(kv.get(key, { recurse: true }, :wait, :wait)).to eql(
            [
              { key: key + 'dewfr', value: 'toast' },
              { key: key, value: 'toast' }
            ]
          )
        end

        it 'GET with nil values' do
          faraday.stub(:get).and_return(OpenStruct.new(headers: headers, status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          allow(kv).to receive_message_chain(:raw, :headers).and_return('x-consul-index' => '12345')
          expect(kv.get(key, { recurse: true, nil_values: true }, :wait, :wait)).to eql(
            [
              { key: key + 'dewfr', value: 'toast' },
              { key: key, value: 'toast' },
              { key: key + 'iamnil', value: nil }
            ]
          )
        end
      end

      context 'ACLs NOT enabled, recurse option ON, convert_to_hash option ON' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key + '/dewfr',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key,
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key + '/iamnil',
                'Value' => nil,
                'Flags' => 0
              },
              {
                'Key' => 'foo',
                'Value' => Base64.encode64('bar'),
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          answer = {}
          answer[key] = {}
          answer[key]['dewfr'] = 'toast'
          answer['foo'] = 'bar'
          expect(kv.get(key, recurse: true, convert_to_hash: true)).to eql(answer)
        end
        it 'GET with nil values' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          answer = {}
          answer[key] = {}
          answer[key]['dewfr'] = 'toast'
          answer[key]['iamnil'] = nil
          answer['foo'] = 'bar'
          expect(kv.get(key, recurse: true, convert_to_hash: true, nil_values: true)).to eql(answer)
        end

        context 'single key value' do
          let(:json) do
            JSON.generate(
              [
                {
                  'Key' => key + '/dewfr',
                  'Value' => Base64.encode64(key_params),
                  'Flags' => 0
                }
              ]
            )
          end

          it 'GET' do
            faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
            kv = Diplomat::Kv.new(faraday)
            answer = {}
            answer[key] = {}
            answer[key]['dewfr'] = 'toast'
            expect(kv.get(key, recurse: true, convert_to_hash: true)).to eql(answer)
          end
        end
      end

      context 'ACLs NOT enabled, keys option ON' do
        let(:json) { JSON.generate([key, key + 'ring', key + 'tar']) }

        it 'GET' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, keys: true)).to eql([key, key + 'ring', key + 'tar'])
        end
      end

      context 'ACLs NOT enabled, decode_values option ON' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key + 'dewfr',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key,
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key + 'iamnil',
                'Value' => nil,
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, decode_values: true)).to include('Key' => key, 'Value' => key_params, 'Flags' => 0)
        end
      end

      context 'ACLs NOT enabled, recurse option ON with transformation' do
        let(:number) { 1 }
        let(:string) { 'x' }
        let(:hash) { '{ "x": 1 }' }
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key + 'number',
                'Value' => Base64.encode64(number.to_s),
                'Flags' => 0
              },
              {
                'Key' => key + 'string',
                'Value' => Base64.encode64("\"#{string}\""),
                'Flags' => 0
              },
              {
                'Key' => key + 'hash',
                'Value' => Base64.encode64(hash),
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key, recurse: true, transformation: proc { |x| JSON.parse("[#{x}]")[0] })).to eql(
            [
              { key: key + 'number', value: number },
              { key: key + 'string', value: string },
              { key: key + 'hash', value: { 'x' => 1 } }
            ]
          )
        end
      end
      context 'ACLs NOT enabled' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key,
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get(key)).to eq('toast')
        end

        it 'GET with consistency param' do
          options = { consistency: 'consistent' }

          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get('key', options)).to eq('toast')
        end
      end
      context 'ACLs enabled, without valid_acl_token' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key,
                'Value' => Base64.encode64('Faraday::ResourceNotFound: the server responded with status 404'),
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET with ACLs enabled, no valid_acl_token' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)

          expect(kv.get(key)).to eq('Faraday::ResourceNotFound: the server responded with status 404')
        end

        it 'GET with consistency param, without valid_acl_token' do
          options = { consistency: 'consistent' }

          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)

          expect(kv.get('key', options)).to eq('Faraday::ResourceNotFound: the server responded with status 404')
        end
      end
      context 'ACLs enabled, with valid_acl_token' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key,
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET with ACLs enabled, valid_acl_token' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)

          expect(kv.get(key)).to eq('toast')
        end
        it 'GET with consistency param, with valid_acl_token' do
          options = { consistency: 'consistent' }

          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)

          expect(kv.get('key', options)).to eq('toast')
        end
      end
    end

    describe '#get_all' do
      context 'normal context' do
        it 'GET_ALL' do
          kv = Diplomat::Kv.new
          stub_request(:get, 'http://localhost:8500/v1/kv/foo?recurse')
            .to_return(OpenStruct.new(status: 200, body: JSON.generate([])))
          kv.get_all('foo')
        end
      end

      context 'datacenter filter' do
        it 'GET_ALL for a specific datacenter' do
          kv = Diplomat::Kv.new
          stub_request(:get, 'http://localhost:8500/v1/kv/foo?dc=bar&recurse')
            .to_return(OpenStruct.new(status: 200, body: JSON.generate([])))
          kv.get_all('foo', dc: 'bar')
        end
      end

      context 'get_all returns no results' do
        let(:json) do
          JSON.generate([])
        end

        it 'GET_ALL and returns an empty Array' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get_all(key)).to eql([])
        end
      end

      context 'recursive get returns only a single result' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key + 'foo',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET_ALL and returns a single item list' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get_all(key)).to eql(
            [
              { key: key + 'foo', value: 'toast' }
            ]
          )
        end

        it 'GET_ALL and returns a hash' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get_all(key, convert_to_hash: true)).to eql(
            key + 'foo' => 'toast'
          )
        end
      end

      context 'recursive get returns multiple nested results' do
        let(:json) do
          JSON.generate(
            [
              {
                'Key' => key + 'foo',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key + 'i/am/nested',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              },
              {
                'Key' => key + 'i/am/also/nested',
                'Value' => Base64.encode64(key_params),
                'Flags' => 0
              }
            ]
          )
        end

        it 'GET_ALL and returns a list' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get_all(key)).to eql(
            [
              { key: key + 'foo', value: 'toast' },
              { key: key + 'i/am/nested', value: 'toast' },
              { key: key + 'i/am/also/nested', value: 'toast' }
            ]
          )
        end

        it 'GET_ALL and returns a hash' do
          faraday.stub(:get).and_return(OpenStruct.new(status: 200, body: json))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.get_all(key, convert_to_hash: true)).to eql(
            'keyfoo' => 'toast',
            'keyi' => {
              'am' => {
                'also' => {
                  'nested' => 'toast'
                },
                'nested' => 'toast'
              }
            }
          )
        end
      end
    end

    describe '#put' do
      context 'ACLs NOT enabled' do
        it 'PUT' do
          faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: "true\n"))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params)).to eq(true)
          expect(kv.value).to eq(key_params)
        end
        it 'PUT with CAS param' do
          options = { cas: modify_index }
          faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: "true\n"))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(true)
          expect(kv.value).to eq(key_params)
        end
      end
      context 'ACLs enabled, without valid_acl_token' do
        it 'PUT with ACLs enabled, no valid_acl_token' do
          faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: "false\n"))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params)).to eq(false)
        end
        it 'PUT with CAS param, without valid_acl_token' do
          options = { cas: modify_index }
          faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: "false\n"))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(false)
        end
      end
      context 'ACLs enabled, with valid_acl_token' do
        it 'PUT with ACLs enabled, valid_acl_token' do
          faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: "true\n"))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)

          expect(kv.put(key, key_params)).to eq(true)
          expect(kv.value).to eq(key_params)
        end
        it 'PUT with CAS param' do
          options = { cas: modify_index }
          faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: "true\n"))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.put(key, key_params, options)).to eq(true)
          expect(kv.value).to eq(key_params)
        end
      end
    end

    describe '#delete' do
      context 'ACLs NOT enabled' do
        it 'DELETE' do
          faraday.stub(:delete).and_return(OpenStruct.new(status: 200))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.delete(key).status).to eq(200)
        end
      end

      context 'ACLs NOT enabled, recurse option ON' do
        it 'DELETE' do
          stub_request(:delete, 'http://localhost:8500/v1/kv/key?recurse')
            .to_return(OpenStruct.new(status: 200))
          kv = Diplomat::Kv.new
          expect(kv.delete(key, recurse: true).status).to eq(200)
        end
      end
      context 'ACLs enabled, without valid_acl_token' do
        it 'DELETE' do
          faraday.stub(:delete).and_return(OpenStruct.new(status: 403))
          kv = Diplomat::Kv.new(faraday)
          expect(kv.delete(key).status).to eq(403)
        end
      end
      context 'ACLs enabled, with valid_acl_token' do
        it 'DELETE' do
          faraday.stub(:delete).and_return(OpenStruct.new(status: 200))
          Diplomat.configuration.acl_token = valid_acl_token
          kv = Diplomat::Kv.new(faraday)
          expect(kv.delete(key).status).to eq(200)
        end
      end
    end

    describe '#txn' do
      before :each do
        Diplomat.configuration.acl_token = nil
      end
      let(:invalid_transaction_format) do
        {
          'KV' => {
            'Verb' => 'get',
            'Key' => 'hello/world'
          }
        }
      end
      let(:invalid_transaction_verb) do
        [
          {
            'KV' => {
              'Verb' => 'invalid_verb'
            }
          }
        ]
      end
      let(:invalid_top_level_key) do
        [
          {
            'kv' => {
              'Verb' => 'get',
              'Key' => 'hello/world'
            }
          }
        ]
      end
      let(:invalid_requirements) do
        [
          {
            'KV' => {
              'Verb' => 'set',
              'Key' => 'hello/world'
            }
          }
        ]
      end
      let(:valid_transaction) do
        [
          {
            'KV' => {
              'Verb' => 'set',
              'Key' => 'test_key',
              'Value' => 'test_value'
            }
          },
          {
            'KV' => {
              'Verb' => 'get',
              'Key' => 'hello/world'
            }
          }
        ]
      end
      let(:valid_return) do
        {
          'Results' => [
            {
              'KV' => {
                'LockIndex' => 0,
                'Key' => 'test_key',
                'Flags' => 0,
                'Value' => nil,
                'CreateIndex' => 2_278_133,
                'ModifyIndex' => 2_278_133
              }
            },
            {
              'KV' => {
                'LockIndex' => 0,
                'Key' => 'hello/world',
                'Flags' => 0,
                'Value' => 'SGVsbG8sIHdvcmxkIQ==',
                'CreateIndex' => 7_639_434,
                'ModifyIndex' => 7_641_028
              }
            }
          ],
          'Errors' => [
            {
              'OpIndex' => 6_345_234,
              'What' => 'Bad stuff happened'
            }
          ]
        }.to_json
      end
      let(:kv) do
        proc do |input, options|
          faraday.stub(:put).and_return(OpenStruct.new(body: valid_return, status: 200))
          kv = Diplomat::Kv.new(faraday)
          kv.txn(input, options)
        end
      end

      let(:rollback_return) do
        {
          # Results is intentionally missing; this can happen in a rolled back transaction
          'Errors' => [
            {
              'OpIndex' => 1,
              'What' => 'failed index check for key "hello/world", current modify index 2 != 1'
            }
          ]
        }
      end
      let(:rollback_kv) do
        proc do |input, options|
          faraday.stub(:put).and_return(OpenStruct.new(body: rollback_return.to_json, status: 409))
          kv = Diplomat::Kv.new(faraday)
          kv.txn(input, options)
        end
      end

      context 'transaction format verification' do
        it 'verifies transaction format' do
          expect { kv.call(invalid_transaction_format, nil) }.to raise_error(Diplomat::InvalidTransaction)
        end

        it 'verifies transaction verbs' do
          expect { kv.call(invalid_transaction_verb, nil) }.to raise_error(Diplomat::InvalidTransaction)
        end

        it 'verifies top level transaction key' do
          expect { kv.call(invalid_top_level_key, nil) }.to raise_error(Diplomat::InvalidTransaction)
        end

        it 'verifies required transaction parameters' do
          expect { kv.call(invalid_requirements, nil) }.to raise_error(Diplomat::InvalidTransaction)
        end
      end

      it 'returns a Hash' do
        expect(kv.call(valid_transaction, {})).to be_a_kind_of(OpenStruct)
      end

      it 'returns arrays as the values' do
        return_values = kv.call(valid_transaction, {})
        return_values.each_pair do |_, values|
          expect(values).to be_a_kind_of(Array)
        end
      end

      it 'returns arrays of Hash objects' do
        return_values = kv.call(valid_transaction, {})
        return_values.each_pair do |_, values|
          values.each do |value|
            expect(value).to be_a_kind_of(Hash)
          end
        end
      end

      it 'returns with the :dc option' do
        dc = 'some-dc'
        options = { dc: dc }
        expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new(body: valid_return, status: 200))
        expect(req).to receive(:url).with("/v1/txn?dc=#{dc}")
        kv.call(valid_transaction, options)
      end

      %w[consistent stale].each do |consistency|
        it "returns with the :consistency #{consistency} option" do
          options = { consistency: consistency }
          expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new(body: valid_return, status: 200))
          expect(req).to receive(:url).with("/v1/txn?#{consistency}")
          kv.call(valid_transaction, options)
        end
      end

      it 'only responds to \'consistent\' or \'stale\' consistencies' do
        options = { consistency: 'bad-value' }
        expect(faraday).to receive(:put).and_yield(req).and_return(OpenStruct.new(body: valid_return, status: 200))
        expect(req).to receive(:url).with('/v1/txn')
        kv.call(valid_transaction, options)
      end

      it 'returns undecoded options' do
        options = { decode_values: false }
        expected_return = kv.call(valid_transaction, options)['Results']
        expect(expected_return.pop['KV']['Value']).to eq('SGVsbG8sIHdvcmxkIQ==')
      end

      it 'handles a rollback with missing results section' do
        expect(rollback_kv.call(valid_transaction, {}).Errors).to eq(rollback_return['Errors'])
      end
    end

    it 'namespaces' do
      faraday.stub(:put).and_return(OpenStruct.new(status: 200, body: "true\n"))
      kv = Diplomat::Kv.new(faraday)

      expect(kv.put("toast/#{key}", key_params)).to eq(true)
      expect(kv.value).to eq(key_params)
    end
  end
end
