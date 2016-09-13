require "logstash/api/rack_app"
require "rack/test"

describe LogStash::Api::RackApp do
  include Rack::Test::Methods

  class DummyApp
    class RaisedError < StandardError; end

    def call(env)
      case env["PATH_INFO"]
      when "/good-page"
        [200, {}, ["200 OK"]]
      when "/service-unavailable"
        [503, {}, ["503 service unavailable"]]
      when "/raise-error"
        raise RaisedError, "Error raised"
      else
        [404, {}, ["404 Page not found"]]
      end
    end
  end

  let(:logger) { double("logger") }

  describe LogStash::Api::RackApp::ApiErrorHandler do
    let(:app) do
      # Scoping in rack builder is weird, these need to be locals
      rack_class = described_class
      rack_logger = logger
      Rack::Builder.new do
        use rack_class, rack_logger
        run DummyApp.new
      end
    end

    it "should let good requests through as normal" do
      get "/good-page"
      expect(last_response).to be_ok
    end

    it "should let through 5xx codes" do
      get "/service-unavailable"
      expect(last_response.status).to eql(503)
    end

    describe "raised exceptions" do
      before do
        allow(logger).to receive(:error).with(any_args)
        get "/raise-error"
      end

      it "should return a 500 error" do
        expect(last_response.status).to eql(500)
      end

      it "should return valid JSON" do
        expect { LogStash::Json.load(last_response.body) }.not_to raise_error
      end

      it "should log the error" do
        expect(logger).to have_received(:error).with(LogStash::Api::RackApp::ApiErrorHandler::LOG_MESSAGE, anything).once
      end
    end
  end

  describe LogStash::Api::RackApp::ApiLogger do
    let(:app) do
      # Scoping in rack builder is weird, these need to be locals
      rack_class = described_class
      rack_logger = logger
      Rack::Builder.new do
        use rack_class, rack_logger
        run DummyApp.new
      end
    end

    it "should log good requests as info" do
      expect(logger).to receive(:debug?).and_return(true)
      expect(logger).to receive(:debug).with(LogStash::Api::RackApp::ApiLogger::LOG_MESSAGE, anything).once
      get "/good-page"
    end

    it "should log 5xx requests as warnings" do
      expect(logger).to receive(:error?).and_return(true)
      expect(logger).to receive(:error).with(LogStash::Api::RackApp::ApiLogger::LOG_MESSAGE, anything).once
      get "/service-unavailable"
    end
  end
end
