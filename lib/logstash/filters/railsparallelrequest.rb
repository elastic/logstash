# parallel request filter
#
# This filter will separate out the parallel requests into separate events.
#

require "logstash/filters/base"
require "logstash/namespace"
require "set"

class LogStash::Filters::Railsparallelrequest < LogStash::Filters::Base

  config_name "railsparallelrequest"
  milestone 1

  public
  def initialize(config = {})
    super
    @threadsafe = false
    @pending = Hash.new
    @last_event = nil
    @recently_error = nil
    @last_uuid = nil
  end

  def register ;end

  def filter(event)
    return unless filter?(event)
    return if event.tags.include? self.class.config_name

    event.tags << self.class.config_name

    line = event["message"]

    if line =~ /^\[(.*?)\]/
      uuid = $1
      event["uuid"] = uuid
      if @recently_error
        if @last_uuid == uuid
          merge_events(@recently_error, event, uuid)
          event.cancel
          return
        else
          @recently_error.uncancel
          yield @recently_error
          @recently_error = nil
        end
      end

      @last_uuid = uuid
      if @pending[uuid]
        merge_events(@pending[uuid], event, uuid)
      else
        @pending[uuid] = event
      end
      @last_event = @pending[uuid]

      if line =~ /Error/
        event.overwrite(@pending[uuid].to_hash)
        @pending.delete uuid
        @recently_error = event
      elsif line =~ /Completed/
        event.overwrite(@pending[uuid])
        @pending.delete uuid
        return
      end
      event.cancel
    elsif @last_event
      @last_event.append(event)
      event.cancel
    end
  end

  def flush
    events = @pending.values.each { |event| event.uncancel }
    @pending.clear
    events
  end

  private
  def merge_events(dest, source, uuid)
    source["message"].gsub!("[#{uuid}]", "")
    dest.append(source)
  end
end
