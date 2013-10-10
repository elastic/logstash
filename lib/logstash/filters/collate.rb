require "logstash/filters/base"
require "logstash/namespace"

# Collate events by time or count.
#
# The original goal of this filter was to merge the logs from different sources
# by the time of log, for example, in real-time log collection, logs can be
# sorted by amount of 3000 logs or can be sorted in 30 seconds.
#
# The config looks like this:
#
#     filter {
#       collate {
#         size => 3000
#         interval => "30s"
#         order => "ascending"
#       }
#     }
class LogStash::Filters::Collate < LogStash::Filters::Base

  config_name "collate"
  milestone 1

  # How many logs should be collated.
  config :count, :validate => :number, :default => 1000

  # The 'interval' is the time window which how long the logs should be sorted. (default 1m)
  config :interval, :validate => :string, :default => "1m"

  # The 'order' collated events should appear in.
  config :order, :validate => ["ascending", "descending"], :default => "ascending"

  public
  def register
    require "thread"
    require "rufus/scheduler"

    @mutex = Mutex.new
    @sortingDone = false
    @sortingArray = Array.new
    @scheduler = Rufus::Scheduler.start_new
    @job = @scheduler.every @interval do
      @logger.info("Scheduler Activated")
      @mutex.synchronize{
        sort
      }
    end
  end # def register

  public
  def filter(event)
    @logger.info("do sort filter")
    if event == LogStash::SHUTDOWN
      @job.trigger()
      @job.unschedule()
      @logger.info("sort filter thread shutdown.")
      return
    end

    # if the event is sorted, a "sorted" tag will be marked, so for those unsorted event, cancel them first.
    if event["tags"].nil? || !event.tags.include?("sorted")
      event.cancel
    else
      return
    end

    @mutex.synchronize{
      @sortingArray.push(event.clone)

      if (@sortingArray.length == @count)
        sort
      end

      if (@sortingDone)
        while sortedEvent = @sortingArray.pop
          sortedEvent["tags"] = Array.new if sortedEvent["tags"].nil?
          sortedEvent["tags"] << "sorted"
          filter_matched(sortedEvent)
          yield sortedEvent
        end # while @sortingArray.pop
        # reset sortingDone flag
        @sortingDone = false
      end
    }
  end # def filter

  private
  def sort
    if (@order == "ascending")
      @sortingArray.sort! { |eventA, eventB| eventB.timestamp <=> eventA.timestamp }
    else 
      @sortingArray.sort! { |eventA, eventB| eventA.timestamp <=> eventB.timestamp }
    end
    @sortingDone = true
  end # def sort

  # Flush any pending messages.
  public
  def flush
    events = []
    if (@sortingDone)
      @mutex.synchronize{
        while sortedEvent = @sortingArray.pop
          sortedEvent["tags"] << "sorted"
          events << sortedEvent
        end # while @sortingArray.pop
      }
      # reset sortingDone flag.
      @sortingDone = false
    end
    return events
  end # def flush
end #
