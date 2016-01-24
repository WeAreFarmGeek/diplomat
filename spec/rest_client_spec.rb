require 'spec_helper'

describe Diplomat::RestClient do

  let(:klass) do
    Class.new Diplomat::RestClient do
      @access_methods = [ :accessible ]

      def accessible(*args)
        args
      end
    end
  end

  context '.method_missing' do
    it 'calls the accessible method on a new instance' do
      dummy = double 'Dummy RestClient'

      expect(klass).to receive(:new).and_return dummy
      expect(dummy).to receive(:accessible).with(1, 2, 3).and_return nil

      klass.method_missing :accessible, 1, 2, 3
    end

    it 'falls back to super' do
      expect(Diplomat::RestClient.superclass).to receive(:method_missing).at_least(:once).and_call_original
      expect{ klass.method_missing :does_not_exist }.to raise_error NoMethodError
    end
  end

  context '.respond_to?' do
    it 'returns true' do
      expect(klass.respond_to? :accessible).to eq true
    end

    it 'falls back to super' do
      expect(Diplomat::RestClient.superclass).to receive(:respond_to?).at_least(:once).and_call_original
      expect(klass.respond_to? :hash).to eq true
    end
  end

  context '.respond_to_missing?' do
    it 'returns true' do
      expect(klass.respond_to_missing? :accessible).to eq true
    end

    it 'falls back to super' do
      expect(Diplomat::RestClient.superclass).to receive(:respond_to_missing?).and_call_original

      klass.respond_to_missing? :hash
    end

    it 'works with Object#method' do
      expect(klass.method :accessible).to be_a Method
      expect(klass.method(:accessible).call 1, 2).to eq [1, 2]
    end

    it 'lets RSpec mock the accessible method' do
      expect(klass).to receive(:accessible).and_call_original
      expect(klass.accessible 1, 2).to eq [1, 2]
    end
  end
end
