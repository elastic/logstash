class LogStash::Inputs::Elastiqueue < LogStash::Inputs::Base
  config_name "elastiqueue"

  config :hosts, :validate => :uri, :list => true
  config :topic, :validate => :string
  config :partitions, :validate => :number
  config :consumer_group, :validate => :string
  config :consumer_name, :validate => :string

  def register
    @elastiqueue = org.logstash.elastiqueue.Elastiqueue.make(hosts.map(&:uri).map(&:to_s))
    @topic = @elastiqueue.topic(topic, partitions)
    @consumer = @topic.makeConsumer(consumer_group, consumer_name)
    @events_processed = java.util.concurrent.atomic.LongAdder.new()
  end

  def run(queue)
    @consumer.ruby_consume_partitions do |events|
      @events_processed.add(events.size)
      queue.push_batch(events)
    end
    last_events_size = 0
    while !stop?
      sleep 1
    end
  end

  def close
    @consumer.close()
    @elastiqueue.close()
  end
end