# encoding: utf-8
# require "logstash/json"
require "logstash/webserver"
require "socket"
require "spec_helper"
require "open-uri"

def block_ports(range)
  servers = []

  range.each do |port|
    server = TCPServer.new("localhost", port)
    Thread.new do
      client = server.accept rescue nil
    end
    servers << server
  end

  sleep(1)
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
  end

  after :all do
    Thread.abort_on_exception = @abort
  end

  let(:logger) { double("logger") }
  let(:agent) { double("agent") }
  let(:webserver) { double("webserver") }

  before :each do
    [:info, :warn, :error, :fatal, :debug].each do |level|
      allow(logger).to receive(level)
    end
    [:info?, :warn?, :error?, :fatal?, :debug?].each do |level|
      allow(logger).to receive(level)
    end

    allow(webserver).to receive(:address).and_return("127.0.0.1")
    allow(agent).to receive(:webserver).and_return(webserver)
  end

  context "when the port is already in use and a range is provided" do
    subject { LogStash::WebServer.new(logger,
                                      agent,
                                      { :http_host => "localhost", :http_ports => port_range
                                      })}

    let(:port_range) { 10000..10010 }
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
        t.kill rescue nil
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
