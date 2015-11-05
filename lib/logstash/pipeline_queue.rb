require 'elasticsearch'
require 'elasticsearch/transport/transport/http/manticore'
require 'securerandom'

java_import java.util.concurrent.SynchronousQueue
java_import java.util.concurrent.TimeUnit

# For dev
Thread.abort_on_exception = true

class ElasticQueue
  attr_reader :name, :size

  class Indexer
    OFFSET_INDEX = ".ls-offsets"

    # This is a sloppy method signature, it should just take the ElasticQueue instance
    def initialize(queue_name, index_queue, process_queue, create_es_client, filterworker_once)
      @queue_name = queue_name
      @uuid = SecureRandom.uuid
      @event_id = 0
      @offset_id = 0
      @background_in = SizedQueue.new(1)
      # This should be a java SynchronousQueue
      @background_out = SizedQueue.new(1)

      @es_client = create_es_client.call
      @index_queue = index_queue
      # This could maybe be a synchronous queue instead?
      @process_queue =process_queue

      @completion_mutex = Mutex.new

      Thread.new {
        process_es_client = create_es_client.call()
        persist_index = ".lsp-#{@queue_name}-#{@uuid}"
        LogStash::Util::set_thread_name("esq-process|#{persist_index}")

        bulk_queue = java.util.concurrent.SynchronousQueue.new()
        Thread.new {

          LogStash::Util::set_thread_name("esq-writer|#{persist_index}")

          while (complete, wrapped_events = bulk_queue.take())
            begin
              bulk_request = wrapped_events.
                select {|wrapped_event| wrapped_event[:event].class == LogStash::Event}.
                flat_map do |wrapped_event|
                [
                  {index: {_index: persist_index, _type: :event, _id: wrapped_event[:id]}},
                  {:event => Marshal.dump(wrapped_event[:event])}
                ]
              end

              # If there are only non-LogStash::Event instances
              process_es_client.bulk body: bulk_request unless bulk_request.empty?
            ensure
              complete.put(true)
            end
          end
        }

        while true
          # Try to grab up to 20 items off the index queue
          wrapped_events = [wrap_event(@index_queue.take())]
          19.times do
            event = @index_queue.poll(10, TimeUnit::MILLISECONDS)
            break if event.nil?
            wrapped_events << wrap_event(event)
          end

          bulk_complete = java.util.concurrent.SynchronousQueue.new()
          bulk_queue.put([bulk_complete, wrapped_events])

          wrapped_events.each {|wrapped_event|
            filterworker_once.call(wrapped_event[:event])
          }

          @es_client.index(
            :index => OFFSET_INDEX,
            :type => :offset,
            :consistency => :one,
            :id => @uuid,
            :body => {offset: wrapped_events.last[:id]}
          )

          # Make sure we aren't leaving an extra request lying around
          bulk_complete.take()
        end
      }
    end

    def wrap_event(event)
      @event_id += 1
      {
        :id => @event_id,
        :event => event,
        :complete => SizedQueue.new(1)
      }
    end
  end

  def initialize(name_, size_)
    @logger = Cabin::Channel.get(LogStash)
    @name = name_
    @size = size_
    @es_client = create_es_client
    @index_queue = java.util.concurrent.SynchronousQueue.new()
    @process_queue = SizedQueue.new(size)
  end

  def create_es_client
    Elasticsearch::Client.new(es_client_settings)
  end

  def es_client_settings
    {
      hosts: ['localhost'],
      transport_class: Elasticsearch::Transport::Transport::HTTP::Manticore
    }
  end

  def push(item)
    @index_queue.put(item)
  end
  alias_method(:<<, :push)

  def pop
    @process_queue.pop()
  end

  def start_indexers(count, filterworker_once)
    count.times.map do |t|
      Indexer.new(name, @index_queue, @process_queue, method(:create_es_client), filterworker_once)
    end
  end

  def start_worker(&filterworker_once)
    @indexers = start_indexers(1, filterworker_once)
  end
end