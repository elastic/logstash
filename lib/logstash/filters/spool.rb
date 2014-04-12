# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "thread"

# spool filter. this is used generally for internal/dev testing.
class LogStash::Filters::Spool < LogStash::Filters::Base
  config_name "spool"
  milestone 1

  def register
    @spool = []
    @spool_lock = Mutex.new # to synchronize between the flush & worker threads
  end # def register

  def filter(event)
    return unless filter?(event)

    filter_matched(event)
    event.cancel
    @spool_lock.synchronize {@spool << event}
  end # def filter

  def flush(options = {})
    @spool_lock.synchronize do
      flushed = @spool.map{|event| event.uncancel; event}
      @spool = []
      flushed
    end
  end

end # class LogStash::Filters::NOOP
