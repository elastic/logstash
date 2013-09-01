# sort filter
#
# This filter will sort messages by timestamp.
# 

require "logstash/filters/base"
require "logstash/namespace"

# The sort filter is for sorting a amount of events or a period of events by timestamp.
#
# The original goal of this filter was to merge the logs from different sources by the time of log,
# for example, in real-time log collection, logs can be sorted by amount of 1000 logs or 
# can be sorted in 30 seconds.
#
# The config looks like this:
#
#     filter {
#       sort {
#         sortSize => 3000
#         sortInterval => "30s"
#         sortBy => "asce"
#       }
#     }
# 
# The 'sortSize' is the window size which how many logs should be sorted.(default 1000)
#
# The 'sortInterval' is the time window which how long the logs should be sorted. (default 1m)
#
# The 'sortBy' can only be "asce" or "desc" (defaults asce), sorted by timestamp asce or desc.
#
class LogStash::Filters::Sort < LogStash::Filters::Base

  config_name "sort"
  plugin_status "experimental"

  config :sortSize, :validate => :number, :default => 1000
  config :sortInterval, :validate => :string, :default => "1m"
  config :sortBy, :validate => ["asce", "desc"], :default => "asce"

  public
  def register
    require "thread"
    require "rufus/scheduler"

    @mutex = Mutex.new
    @sortingDone = false
    @sortingArray = Array.new
    @scheduler = Rufus::Scheduler.start_new
    @job = @scheduler.every @sortInterval do
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

    # if the event is sorted, a "sorted" tag will be marked.
    if (!event.tags.include?"sorted")
      event.cancel
    else
      return
    end

    @mutex.synchronize{
      if (@sortingArray.length == @sortSize)
        sort
      end

      if (@sortingDone)
        while sortedEvent = @sortingArray.pop
          sortedEvent.tags << "sorted"
          filter_matched(sortedEvent)
          yield sortedEvent
        end # while @sortingArray.pop
        # reset sortingDone flag
        @sortingDone = false
      end

      @sortingArray.push(event.clone)
    }
  end # def filter

  private
  def sort
    if (@sortBy == "asce")
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
          sortedEvent.tags << "sorted"
          events << sortedEvent
        end # while @sortingArray.pop
      }
      # reset sortingDone flag.
      @sortingDone = false
    end
    return events
  end # def flush
end #