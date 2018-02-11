class LogStash::Outputs::Elastiqueue < LogStash::Outputs::Base
  config_name "elastiqueue"
  concurrency :shared

  config :host, :validate => :uri
  config :topic, :validate => :string
  config :partitions, :validate => :number

  def register
    @elastiqueue = org.logstash.elastiqueue.Elastiqueue.make(host)
    @topic = @elastiqueue.topic(topic, partitions)
    @producer = @topic.makeProducer("A producer")
  end

  def multi_receive(events)
    encoded.each do |events|
      @producer.rubyWrite(events)
    end
  end
end