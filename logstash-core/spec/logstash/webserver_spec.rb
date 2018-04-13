# encoding: utf-8
# require "logstash/json"
require "logstash/webserver"
require_relative "../support/helpers"
require "socket"
require "spec_helper"
require "open-uri"
require "webmock/rspec"

def block_ports(range)
  servers = []

  range.each do |port|
    begin
      server = TCPServer.new("localhost", port)
      servers << server
    rescue => e
      # The port can already be taken
    end
  end

  servers
end

def free_ports(servers)
  servers.each do |t|
    t.close rescue nil # the threads are blocked just kill
  end
end

describe LogStash::WebServer do
  before :all do
    @abort = Thread.abort_on_exception
    Thread.abort_on_exception = true
    WebMock.allow_net_connect!
  end

  after :all do
    Thread.abort_on_exception = @abort
  end

  let(:logger) { LogStash::Logging::Logger.new("testing") }
  let(:agent) { OpenStruct.new({:webserver => webserver, :http_address => "127.0.0.1", :id => "myid", :name => "myname"}) }
  let(:webserver) { OpenStruct.new({}) }

  subject { LogStash::WebServer.new(logger,
                                    agent,
                                    { :http_host => "localhost", :http_ports => port_range })}

  let(:port_range) { 10000..10010 }

  context "when an exception occur in the server thread" do
    let(:spy_output) { spy("stderr").as_null_object }

    it "should not log to STDERR" do
      skip("This test fails randomly, tracked in https://github.com/elastic/logstash/issues/9361.")
      backup_stderr = STDERR
      backup_stdout = STDOUT

      # We are redefining constants, so lets silence the warning
      silence_warnings do
        STDOUT = STDERR = spy_output
      end

      expect(spy_output).not_to receive(:puts).with(any_args)
      expect(spy_output).not_to receive(:write).with(any_args)

      # This trigger an infinite loop in the reactor
      expect(IO).to receive(:select).and_raise(IOError).at_least(:once)

      t = Thread.new do
        subject.run
      end

      sleep(1)

      # We cannot use stop here, since the code is stuck in an infinite loop
      t.kill
      t.join

      silence_warnings do
        STDERR = backup_stderr
        STDOUT = backup_stdout
      end
    end
  end

  context "when the port is already in use and a range is provided" do
    after(:each) { free_ports(@servers) }

    context "when we have available ports" do
      before(:each) do
        @servers = block_ports(10000..10005)
      end

      it "successfully find an available port" do
        t = Thread.new do
          subject.run
        end

        sleep(1)

        response = open("http://localhost:10006").read
        expect { LogStash::Json.load(response) }.not_to raise_error
        expect(subject.address).to eq("localhost:10006")

        subject.stop
        t.join
      end
    end

    context "when all the ports are taken" do
      before(:each) do
        @servers = block_ports(port_range)
      end

      it "raise an exception" do
        expect { subject.run }.to raise_error(Errno::EADDRINUSE, /Logstash tried to bind to port range/)
      end
    end
  end
end

describe LogStash::IOWrappedLogger do
  let(:logger)  { spy("logger") }
  let(:message) { "foobar" }

  subject { described_class.new(logger) }

  it "responds to puts" do
    subject.puts(message)
    expect(logger).to have_received(:debug).with(message)
  end

  it "responds to write" do
    subject.write(message)
    expect(logger).to have_received(:debug).with(message)
  end

  it "responds to <<" do
    subject << message
    expect(logger).to have_received(:debug).with(message)
  end

  it "responds to sync=(v)" do
    expect{ subject.sync = true }.not_to raise_error
  end
end
