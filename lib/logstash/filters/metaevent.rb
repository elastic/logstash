require "logstash/filters/base"
require "logstash/namespace"

class LogStash::Filters::Metaevent < LogStash::Filters::Base
  config_name "metaevent"
  plugin_status "experimental"

  config :followed_by_tags, :validate => :array

  config :period, :validate => :number

  def register
    reset_state
  end

  def filter(event)
    if filter?(event)
      start_period(event)
    else if within_period && followed_by_tags_match(event)
      trigger(event)
    else
      @logger.debug([@add_tag, "ignoring", event])
    end
  end

  def flush
    return if @metaevents.empty?

    new_events = @metaevents
    @metaevents = []
    new_events
  end

  private

  def start_period
    @logger.debug([@add_tag, "start_period", event])
    @start_event = event
  end

  def trigger(event)
    @logger.debug([@add_tag, "trigger", event])
    reset_state
  end

  def followed_by_tags_match(event)
    !event.empty? && (event.tags & @followed_by_tags).size == @followed_by_tags.size
  end

  def within_period
    @start_event.ruby_timestamp + @period < Time.now
  end

  def reset_state
    @metaevents = []
    @start_event = nil
  end
end
