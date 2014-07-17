# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# spool filter. this is used generally for internal/dev testing.
class LogStash::Filters::Spool < LogStash::Filters::Base
  config_name "spool"
  milestone 1

  def register
    @spool = []
  end # def register

  def filter(event)
    return unless filter?(event)

    filter_matched(event)
    event.cancel
    @spool << event
  end # def filter

  def flush(options = {})
    flushed = @spool.map{|event| event.uncancel; event}
    @spool = []
    flushed
  end

end # class LogStash::Filters::NOOP
