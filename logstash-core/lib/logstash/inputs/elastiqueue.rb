class LogStash::Inputs::Elastiqueue < LogStash::Inputs::Base
  config_name "elastiqueue"

  config :host, :validate => :uri
  config :topic, :validate => :string
  config :partitions, :validate => :number
  config :consumer_group, :validate => :string
  config :consumer_name, :validate => :string

  def register
    @elastiqueue = org.logstash.elastiqueue.Elastiqueue.make(host.to_s)
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
      last_events_size = @events_processed.long_value
      sleep 1
      puts "Accumulated " + @events_processed.long_value.to_s
      break if @events_processed.long_value == last_events_size
    end
    close
  end

  def close
    @consumer.close()
    @elastiqueue.close()
  end
end