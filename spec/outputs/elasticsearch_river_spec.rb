# encoding: utf-8

require "logstash/plugin"

describe "outputs/elasticsearch_river" do

  it "should register" do
    output = LogStash::Plugin.lookup("output", "elasticsearch_river").new("es_host" => "localhost", "rabbitmq_host" => "localhost")
    output.stub(:prepare_river)

    # register will try to load jars and raise if it cannot find jars
    expect {output.register}.to_not raise_error
  end
end
