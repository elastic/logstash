# encoding: utf-8

require "logstash/plugin"

describe "inputs/log4j" do

  it "should register" do
    input = LogStash::Plugin.lookup("input", "log4j").new("mode" => "client")

    # register will try to load jars and raise if it cannot find jars or if org.apache.log4j.spi.LoggingEvent class is not present
    expect {input.register}.to_not raise_error
  end
end
