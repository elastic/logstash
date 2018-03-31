class LogStash::Outputs::Elastiqueue < LogStash::Outputs::Base
  config_name "elastiqueue"
  concurrency :shared

  config :hosts, :validate => :uri, :list => true
  config :topic, :validate => :string
  config :partitions, :validate => :number
  config :user, :validate => :string
  config :password, :validate => :password

  def register
    plain_password = password ? password.value : nil
    @elastiqueue = org.logstash.elastiqueue.Elastiqueue.make(user, plain_password, hosts.map(&:uri).map(&:to_s).to_a)
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