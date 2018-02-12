class LogStash::Outputs::Elastiqueue < LogStash::Outputs::Base
  config_name "elastiqueue"
  concurrency :shared

  config :hosts, :validate => :uri, :list => true
  config :topic, :validate => :string
  config :partitions, :validate => :number

  def register
    @elastiqueue = org.logstash.elastiqueue.Elastiqueue.make(hosts.map(&:uri).map(&:to_s).to_a)
    @topic = @elastiqueue.topic(topic, partitions)
    @producer = @topic.makeProducer("A producer")
  end

  def multi_receive(events)
    @producer.rubyWrite(events)
  end

  def close
    @producer.close
    @elastiqueue.close
  end
end