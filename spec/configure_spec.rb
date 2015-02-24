require 'spec_helper'

describe Diplomat do

  describe "configuration" do
    before(:each) do
      expect(Diplomat.configuration).to_not be_nil
      expect(Diplomat.configuration).to be_a Diplomat::Configuration
      Diplomat.configuration = Diplomat::Configuration.new
    end

    it "has configuration block"  do
      expect { |b| Diplomat.configure(&b) }.to yield_control
    end

    context "Default" do
      let(:config) { Diplomat.configuration }

      it "Returns a Diplmant::Configuration" do
        expect(config).to be_a Diplomat::Configuration
      end

      it "Returns a default URL" do
        expect(config.url).to_not be_nil
        expect(config.url.length).to be > 0
      end

      it "Returns no default middleware" do
        expect(config.middleware).to be_a(Array)
        expect(config.middleware.length).to eq(0)
      end
    end

    context "Custom Configuration" do

      class StubMiddleware
        def initialize(app, options = {})
          @app = app
          @options = options
        end
        def call(env)
          @app.call(env)
        end
      end

      it "Sets the correct configuration" do
        Diplomat.configure do |config|
          config.url = "http://google.com"
          config.acl_token = "f45cbd0b-5022-47ab-8640-4eaa7c1f40f1"
          config.middleware = StubMiddleware
        end

        expect(Diplomat.configuration.url).to eq("http://google.com")
        expect(Diplomat.configuration.acl_token).to eq("f45cbd0b-5022-47ab-8640-4eaa7c1f40f1")
        expect(Diplomat.configuration.middleware).to be_a(Array)
        expect(Diplomat.configuration.middleware.first).to eq(StubMiddleware)
      end

      it "Can set multiple middleware" do
        Diplomat.configure do |config|
          config.middleware = [StubMiddleware, StubMiddleware, StubMiddleware]
        end

        expect(Diplomat.configuration.middleware).to be_a(Array)
        expect(Diplomat.configuration.middleware.length).to eq(3)
        expect(Diplomat.configuration.middleware.first).to eq(StubMiddleware)
      end
    end
  end
end
