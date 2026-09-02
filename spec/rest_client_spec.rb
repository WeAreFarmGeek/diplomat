# frozen_string_literal: true

require 'spec_helper'

describe Diplomat::RestClient do
  let(:klass) do
    Class.new Diplomat::RestClient do
      @access_methods = [:accessible]

      def accessible(*args)
        args
      end
    end
  end

  context '.access_methods' do
    let(:declared_klass) do
      Class.new Diplomat::RestClient do
        access_methods [:accessible]

        def accessible(*args)
          args
        end
      end
    end

    it 'defines the method on the class' do
      expect(declared_klass.methods).to include(:accessible)
      expect(Diplomat::Kv.methods).to include(:get, :put, :delete)
    end

    it 'forwards to a new instance' do
      dummy = double 'Dummy RestClient'

      expect(declared_klass).to receive(:new).and_return(dummy)
      expect(dummy).to receive(:accessible).with(1, 2, 3).and_return(nil)

      declared_klass.accessible(1, 2, 3)
    end

    it 'leaves methods Ruby already defines alone' do
      klass = Class.new(Diplomat::RestClient) { access_methods [:clone] }

      expect(klass.clone).to be_a(Class)
    end
  end

  context '.method_missing' do
    it 'calls the accessible method on a new instance' do
      dummy = double 'Dummy RestClient'

      expect(klass).to receive(:new).and_return(dummy)
      expect(dummy).to receive(:accessible).with(1, 2, 3).and_return(nil)

      klass.method_missing(:accessible, 1, 2, 3)
    end

    it 'falls back to super' do
      expect(Diplomat::RestClient.superclass).to receive(:method_missing).at_least(:once).and_call_original
      expect { klass.method_missing(:does_not_exist) }.to raise_error(NoMethodError)
    end
  end

  context '.respond_to?' do
    it 'returns true' do
      expect(klass.respond_to?(:accessible)).to eq(true)
    end

    it 'falls back to super' do
      expect(Diplomat::RestClient.superclass).to receive(:respond_to?).at_least(:once).and_call_original
      expect(klass.respond_to?(:hash)).to eq(true)
    end
  end

  context '.respond_to_missing?' do
    it 'returns true' do
      expect(klass.respond_to_missing?(:accessible)).to eq(true)
    end

    it 'falls back to super' do
      expect(Diplomat::RestClient.superclass).to receive(:respond_to_missing?).and_call_original

      klass.respond_to_missing? :hash
    end

    it 'works with Object#method' do
      expect(klass.method(:accessible)).to be_a(Method)
      expect(klass.method(:accessible).call(1, 2)).to eq([1, 2])
    end

    it 'lets RSpec mock the accessible method' do
      expect(klass).to receive(:accessible).and_call_original
      expect(klass.accessible(1, 2)).to eq([1, 2])
    end
  end
end
