# encoding: utf-8
require "fileutils"
require "logstash/event"

module LogStash
  class QueueFactory
    def self.create(settings)
      queue_type = settings.get("queue.type")
      queue_page_capacity = settings.get("queue.page_capacity")
      queue_max_bytes = settings.get("queue.max_bytes")
      queue_max_events = settings.get("queue.max_events")
      checkpoint_max_acks = settings.get("queue.checkpoint.acks")
      checkpoint_max_writes = settings.get("queue.checkpoint.writes")
      checkpoint_max_interval = settings.get("queue.checkpoint.interval")

      queue_path = ::File.join(settings.get("path.queue"), settings.get("pipeline.id"))

      case queue_type
      when "persisted"
        # persisted is the disk based acked queue
        FileUtils.mkdir_p(queue_path)
        LogStash::WrappedAckedQueue.new(queue_path, queue_page_capacity, queue_max_events, checkpoint_max_writes, checkpoint_max_acks, checkpoint_max_interval, queue_max_bytes)
      when "memory"
        # memory is the legacy and default setting
        LogStash::WrappedSynchronousQueue.new(
          settings.get("pipeline.batch.size") * settings.get("pipeline.workers") * 2
        )
      else
        raise ConfigurationError, "Invalid setting `#{queue_type}` for `queue.type`, supported types are: 'memory' or 'persisted'"
      end
    end
  end
end
