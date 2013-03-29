require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Metaevent < LogStash::Filters::Base
  config_name "metaevent"
  plugin_status "experimental"

  # syntax: `followed_by_tags => [ "tag", "tag" ]`
  config :followed_by_tags, :validate => :array, :required => true

  # syntax: `period => 60`
  config :period, :validate => :number, :default => 30

  def register
    @logger.debug("registering")
    @metaevents = []
  end

  def filter(event)
    if filter?(event)
      start_period(event)
    elsif within_period(event)
      if followed_by_tags_match(event)
        trigger(event)
      else
        @logger.debug(["metaevent", @add_tag, "ignoring (tags don't match)", event])
      end
    else
      @logger.debug(["metaevent", @add_tag, "ignoring (not in period)", event])
    end
  end

  def flush
    return if @metaevents.empty?

    new_events = @metaevents
    @metaevents = []
    new_events
  end

  private

  def start_period(event)
    @logger.debug(["metaevent", @add_tag, "start_period", event])
    @start_event = event
  end

  def trigger(event)
    @logger.debug(["metaevent", @add_tag, "trigger", event])

    event = LogStash::Event.new
    event.source_host = Socket.gethostname
    event["tags"] = @add_tag

    @metaevents << event
    @start_event = nil
  end

  def followed_by_tags_match(event)
    (event.tags & @followed_by_tags).size == @followed_by_tags.size
  end

  def within_period(event)
    time_delta = event.ruby_timestamp - @start_event.ruby_timestamp
    time_delta >= 0 && time_delta <= @period
  end
end
