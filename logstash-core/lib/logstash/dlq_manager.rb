# encoding: utf-8
require "fileutils"

require "logstash/namespace"

module LogStash; class DeadLetterQueueManager
  include LogStash::Util::Loggable
  @@current_queue_name = "_current"

  def initialize(path)
    @path = path
    @capacity = 5248800
    @max_events = 0
    @checkpoint_max_writes = 1
    @checkpoint_max_acks = 1
    @checkpoint_max_interval = 0
    @max_bytes = 0
    @element_class = "org.logstash.DLQEntry"
    @mutex = Mutex.new
    @queues = build_queue_state_from_disk
    @current_queue_path = ::File.join(@path, @@current_queue_name)
    unless @queues.key?(@@current_queue_name)
      @queues[@@current_queue_name] = build_queue_with_name(@@current_queue_name)
    end
    @queues[@@current_queue_name].open
  end

  def build_queue_with_name(name)
    dlq_path = ::File.join(@path, name)
    FileUtils.mkdir_p(dlq_path)
    LogStash::Util::WrappedAckedQueue.create_file_based(dlq_path, @capacity, @max_events,
                                                        @checkpoint_max_writes, @checkpoint_max_acks,
                                                        @checkpoint_max_interval, @max_bytes,
                                                        @element_class)
  end

  def build_queue_state_from_disk
    if ::File.exists? @path
      names = Dir.entries(@path).select {|entry| !(entry =='.' || entry == '..')}
      Hash[ names.map { |name| [name, build_queue_with_name(name)] } ]
    else
      {}
    end
  end

  def queues
    @queues.keys
  end

  def close
    @mutex.synchronize do
      @queues.each { |q| q.close }
    end
  end

  def rollover(new_name)
    @mutex.synchronize do
      if new_name == @@current_queue_name
        raise Error, "cannot name your queue #{@@current_queue_name}"
      end

      if ::File.exists?(::File.join(@path, new_name))
        raise Error, "cannot name queue #{new_name}, already exists"
      end

      current_queue = @queues.delete(@@current_queue_name)
      current_queue.close

      ::File.rename @current_queue_path, ::File.join(@path, new_name)

      @queues.merge!({
        @@current_queue_name => build_queue_with_name(@@current_queue_name),
        new_name => build_queue_with_name(new_name)
      })
      @queues[@@current_queue_name].open
    end
  end

  def delete(name)
    @mutex.synchronize do
      if name == @@current_queue_name
        raise Error, "cannot delete the current queue"
      end

      queue = @queues.delete(name)
      queue.close
      FileUtils.rm_rf(::File.join(@path, name))
      true
    end
  end

  def write(event)
    @mutex.synchronize do
      @queues[@@current_queue_name].write_client << event
    end
  end
end end
