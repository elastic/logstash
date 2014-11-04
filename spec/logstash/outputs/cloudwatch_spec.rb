require "spec_helper"
require "logstash/plugin"
require "logstash/json"

describe "outputs/cloudwatch" do
  

  output = LogStash::Plugin.lookup("output", "cloudwatch").new

  it "should register" do
    expect {output.register}.to_not raise_error
  end

  it "should respond correctly to a receive call" do
    event = LogStash::Event.new
    expect { output.receive(event) }.to_not raise_error
  end
end
