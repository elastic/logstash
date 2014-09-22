require 'logstash/namespace'
require 'logstash/inputs/base'

# This input will read events from a Kafka topic. It uses the high level consumer API provided
# by Kafka to read messages from the broker. It also maintains the state of what has been
# consumed using Zookeeper. The default input codec is json
#
# The only required configuration is the topic name. By default it will connect to a Zookeeper
# running on localhost. All the broker information is read from Zookeeper state
#
# Ideally you should have as many threads as the number of partitions for a perfect balance --
# more threads than partitions means that some threads will be idle
#
# For more information see http://kafka.apache.org/documentation.html#theconsumer
#
# Kafka consumer configuration: http://kafka.apache.org/documentation.html#consumerconfigs
#
class LogStash::Inputs::Kafka < LogStash::Inputs::Base
  config_name 'kafka'
  milestone 1

  default :codec, 'json'

  # Specifies the ZooKeeper connection string in the form hostname:port where host and port are
  # the host and port of a ZooKeeper server. You can also specify multiple hosts in the form
  # hostname1:port1,hostname2:port2,hostname3:port3.
  #
  # The server may also have a ZooKeeper chroot path as part of it's ZooKeeper connection string
  # which puts its data under some path in the global ZooKeeper namespace. If so the consumer
  # should use the same chroot path in its connection string. For example to give a chroot path of
  # /chroot/path you would give the connection string as
  # hostname1:port1,hostname2:port2,hostname3:port3/chroot/path.
  config :zk_connect, :validate => :string, :default => 'localhost:2181'
  # A string that uniquely identifies the group of consumer processes to which this consumer
  # belongs. By setting the same group id multiple processes indicate that they are all part of
  # the same consumer group.
  config :group_id, :validate => :string, :default => 'logstash'
  # The topic to consume messages from
  config :topic_id, :validate => :string, :required => true
  # Specify whether to jump to beginning of the queue when there is no initial offset in
  # ZooKeeper, or if an offset is out of range. If this is false, messages are consumed
  # from the latest offset
  #
  # If reset_beginning is true, the consumer will check ZooKeeper to see if any other group members
  # are present and active. If not, the consumer deletes any offset information in the ZooKeeper
  # and starts at the smallest offset. If other group members are present reset_beginning will not
  # work and the consumer threads will rejoin the consumer group.
  config :reset_beginning, :validate => :boolean, :default => false
  # Number of threads to read from the partitions. Ideally you should have as many threads as the
  # number of partitions for a perfect balance. More threads than partitions means that some
  # threads will be idle. Less threads means a single thread could be consuming from more than
  # one partition
  config :consumer_threads, :validate => :number, :default => 1
  # Internal Logstash queue size used to hold events in memory after it has been read from Kafka
  config :queue_size, :validate => :number, :default => 20
  # When a new consumer joins a consumer group the set of consumers attempt to "rebalance" the
  # load to assign partitions to each consumer. If the set of consumers changes while this
  # assignment is taking place the rebalance will fail and retry. This setting controls the
  # maximum number of attempts before giving up.
  config :rebalance_max_retries, :validate => :number, :default => 4
  # Backoff time between retries during rebalance.
  config :rebalance_backoff_ms, :validate => :number, :default => 2000
  # Throw a timeout exception to the consumer if no message is available for consumption after
  # the specified interval
  config :consumer_timeout_ms, :validate => :number, :default => -1
  # Option to restart the consumer loop on error
  config :consumer_restart_on_error, :validate => :boolean, :default => true
  # Time in millis to wait for consumer to restart after an error
  config :consumer_restart_sleep_ms, :validate => :number, :default => 0
  # Option to add Kafka metadata like topic, message size to the event
  config :decorate_events, :validate => :boolean, :default => false
  # A unique id for the consumer; generated automatically if not set.
  config :consumer_id, :validate => :string, :default => nil
  # The number of byes of messages to attempt to fetch for each topic-partition in each fetch
  # request. These bytes will be read into memory for each partition, so this helps control
  # the memory used by the consumer. The fetch request size must be at least as large as the
  # maximum message size the server allows or else it is possible for the producer to send
  # messages larger than the consumer can fetch.
  config :fetch_message_max_bytes, :validate => :number, :default => 1048576

  public
  def register
    jarpath = File.join(File.dirname(__FILE__), '../../../vendor/jar/kafka*/libs/*.jar')
    Dir[jarpath].each do |jar|
      require jar
    end
    require 'jruby-kafka'
    options = {
        :zk_connect => @zk_connect,
        :group_id => @group_id,
        :topic_id => @topic_id,
        :rebalance_max_retries => @rebalance_max_retries,
        :rebalance_backoff_ms => @rebalance_backoff_ms,
        :consumer_timeout_ms => @consumer_timeout_ms,
        :consumer_restart_on_error => @consumer_restart_on_error,
        :consumer_restart_sleep_ms => @consumer_restart_sleep_ms,
        :consumer_id => @consumer_id,
        :fetch_message_max_bytes => @fetch_message_max_bytes
    }
    if @reset_beginning
      options[:reset_beginning] = 'from-beginning'
    end # if :reset_beginning
    @kafka_client_queue = SizedQueue.new(@queue_size)
    @consumer_group = Kafka::Group.new(options)
    @logger.info('Registering kafka', :group_id => @group_id, :topic_id => @topic_id, :zk_connect => @zk_connect)
  end # def register

  public
  def run(logstash_queue)
    java_import 'kafka.common.ConsumerRebalanceFailedException'
    @logger.info('Running kafka', :group_id => @group_id, :topic_id => @topic_id, :zk_connect => @zk_connect)
    begin
      @consumer_group.run(@consumer_threads,@kafka_client_queue)
      begin
        while true
          event = @kafka_client_queue.pop
          queue_event("#{event}",logstash_queue)
        end
      rescue LogStash::ShutdownSignal
        @logger.info('Kafka got shutdown signal')
        @consumer_group.shutdown
      end
      until @kafka_client_queue.empty?
        queue_event("#{@kafka_client_queue.pop}",logstash_queue)
      end
      @logger.info('Done running kafka input')
    rescue => e
      @logger.warn('kafka client threw exception, restarting',
                   :exception => e)
      if @consumer_group.running?
        @consumer_group.shutdown
      end
      sleep(Float(@consumer_restart_sleep_ms) * 1 / 1000)
      retry
    end
    finished
  end # def run

  private
  def queue_event(msg, output_queue)
    begin
      @codec.decode(msg) do |event|
        decorate(event)
        if @decorate_events
          event['kafka'] = {:msg_size => msg.bytesize, :topic => @topic_id, :consumer_group => @group_id}
        end
        output_queue << event
      end # @codec.decode
    rescue => e # parse or event creation error
      @logger.error('Failed to create event', :message => msg, :exception => e,
                    :backtrace => e.backtrace)
    end # begin
  end # def queue_event

end #class LogStash::Inputs::Kafka
