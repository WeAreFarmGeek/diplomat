require 'spec_helper'
require 'json'
require 'base64'

describe Diplomat::Event do

  before :all do
    @empty_json = '[]'
    @events_json =
    '[{"ID":"b8a5d478-c370-28b1-cd04-9547877bf767","Name":"test","Payload":"eyBrZXk6IDEgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":327},
      {"ID":"7261716d-edf1-398e-8d14-e29eea37bd9d","Name":"test","Payload":"eyBrZXk6IDIgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":328},
      {"ID":"9c98eddb-5bbe-9035-435f-2385b3484203","Name":"test","Payload":"eyBrZXk6IDMgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":329},
      {"ID":"426f6761-3c67-d3f1-f228-a8d958d59ab3","Name":"test","Payload":"eyBrZXk6IDQgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":330},
      {"ID":"e0c7e975-fdc3-6c8b-fb8f-0a667ecb221c","Name":"test","Payload":"eyBrZXk6IDUgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":331},
      {"ID":"c5e1391b-1559-ca52-2ef5-ba9ab5808806","Name":"test","Payload":"eyBrZXk6IDYgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":332},
      {"ID":"7981ed88-1fd2-5002-ee7f-05b56063339e","Name":"test","Payload":"eyBrZXk6IDcgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":333},
      {"ID":"8bc6e729-2a27-5116-16f4-44df4897e356","Name":"test","Payload":"eyBrZXk6IDggfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":334},
      {"ID":"408ef226-0b30-04db-2b73-e57c73160cf3","Name":"test","Payload":"eyBrZXk6IDkgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":335},
      {"ID":"134538e5-2ad7-67b2-cc3a-422526d145fa","Name":"test","Payload":"eyBrZXk6IDEwIH0=","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":336}]'
    @events_next_json =
    '[{"ID":"b8a5d478-c370-28b1-cd04-9547877bf767","Name":"test","Payload":"eyBrZXk6IDEgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":327},
      {"ID":"7261716d-edf1-398e-8d14-e29eea37bd9d","Name":"test","Payload":"eyBrZXk6IDIgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":328},
      {"ID":"9c98eddb-5bbe-9035-435f-2385b3484203","Name":"test","Payload":"eyBrZXk6IDMgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":329},
      {"ID":"426f6761-3c67-d3f1-f228-a8d958d59ab3","Name":"test","Payload":"eyBrZXk6IDQgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":330},
      {"ID":"e0c7e975-fdc3-6c8b-fb8f-0a667ecb221c","Name":"test","Payload":"eyBrZXk6IDUgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":331},
      {"ID":"c5e1391b-1559-ca52-2ef5-ba9ab5808806","Name":"test","Payload":"eyBrZXk6IDYgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":332},
      {"ID":"7981ed88-1fd2-5002-ee7f-05b56063339e","Name":"test","Payload":"eyBrZXk6IDcgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":333},
      {"ID":"8bc6e729-2a27-5116-16f4-44df4897e356","Name":"test","Payload":"eyBrZXk6IDggfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":334},
      {"ID":"408ef226-0b30-04db-2b73-e57c73160cf3","Name":"test","Payload":"eyBrZXk6IDkgfQ==","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":335},
      {"ID":"134538e5-2ad7-67b2-cc3a-422526d145fa","Name":"test","Payload":"eyBrZXk6IDEwIH0=","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":336},
      {"ID":"cc4e38a8-7faa-b3b2-b5cb-7ba9839b7b5b","Name":"test","Payload":"eyBrZXk6IDExIH0=","NodeFilter":"","ServiceFilter":"","TagFilter":"","Version":1,"LTime":337}]'
    @events_expected =
     [{name: "test", payload: "{ key: 1 }"},
      {name: "test", payload: "{ key: 2 }"},
      {name: "test", payload: "{ key: 3 }"},
      {name: "test", payload: "{ key: 4 }"},
      {name: "test", payload: "{ key: 5 }"},
      {name: "test", payload: "{ key: 6 }"},
      {name: "test", payload: "{ key: 7 }"},
      {name: "test", payload: "{ key: 8 }"},
      {name: "test", payload: "{ key: 9 }"},
      {name: "test", payload: "{ key: 10 }"}]
    @events_next_expected =
     [{name: "test", payload: "{ key: 1 }"},
      {name: "test", payload: "{ key: 2 }"},
      {name: "test", payload: "{ key: 3 }"},
      {name: "test", payload: "{ key: 4 }"},
      {name: "test", payload: "{ key: 5 }"},
      {name: "test", payload: "{ key: 6 }"},
      {name: "test", payload: "{ key: 7 }"},
      {name: "test", payload: "{ key: 8 }"},
      {name: "test", payload: "{ key: 9 }"},
      {name: "test", payload: "{ key: 10 }"},
      {name: "test", payload: "{ key: 11 }"}]
    @event_name = "test"
    @event_first = { value: {name: "test", payload: "{ key: 1 }"}, token: "b8a5d478-c370-28b1-cd04-9547877bf767" }
    @token_mid = "e0c7e975-fdc3-6c8b-fb8f-0a667ecb221c"
    @event_mid   = { value: {name: "test", payload: "{ key: 6 }"}, token: "c5e1391b-1559-ca52-2ef5-ba9ab5808806" }
    @event_last  = { value: {name: "test", payload: "{ key: 10 }"}, token: "134538e5-2ad7-67b2-cc3a-422526d145fa" }
    @event_next  = { value: {name: "test", payload: "{ key: 11 }"}, token: "cc4e38a8-7faa-b3b2-b5cb-7ba9839b7b5b" }
  end


  describe "#get_all" do

    context "empty list" do
      let(:faraday) { double("Faraday") }

      it "default args act the same as (:reject, _)" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @empty_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect{ev.get_all(@event_name)}.to raise_error(Diplomat::EventNotFound, @event_name)
      end
      it "throws when asked to :reject" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @empty_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect{ev.get_all(@event_name, :reject)}.to raise_error(Diplomat::EventNotFound, @event_name)
      end
      it "retries and returns when asked to :wait" do
        expect(faraday).to receive(:get).twice.and_return(
            OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @empty_json }),
            OpenStruct.new({ status: 200, headers: {"x-consul-index" => "69"}, body: @events_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(@event_name, :wait)).to eql(@events_expected)
      end
    end

    context "non-empty list" do
      let(:faraday) { double("Faraday") }

      it "default args act the same as (_, :return)" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(@event_name)).to eql(@events_expected)
      end
      it "throws when asked to :reject" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect{ev.get_all(@event_name, :reject, :reject)}.to raise_error(Diplomat::EventAlreadyExists, @event_name)
      end
      it "returns when asked to :return" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(@event_name, :reject, :return)).to eql(@events_expected)
      end
      it "retries and returns when asked to :wait" do
        expect(faraday).to receive(:get).twice.and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json }),
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "69"}, body: @events_next_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get_all(@event_name, :reject, :wait)).to eql(@events_next_expected)
      end
    end

  end


  describe "#get" do

    context "non-empty list" do
      let(:faraday) { double("Faraday") }

      it "gets first item" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(@event_name, :first)).to eql(@event_first)
      end
      it "gets last item" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(@event_name, :last)).to eql(@event_last)
      end
      it "gets mid-sequence item" do
        expect(faraday).to receive(:get).and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(@event_name, @token_mid)).to eql(@event_mid)
      end
      it "retries and returns next item" do
        expect(faraday).to receive(:get).twice.and_return(
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "42"}, body: @events_json }),
          OpenStruct.new({ status: 200, headers: {"x-consul-index" => "69"}, body: @events_next_json })
        )
        ev = Diplomat::Event.new(faraday)
        expect(ev.get(@event_name, :next)).to eql(@event_next)
      end
    end

  end
end
