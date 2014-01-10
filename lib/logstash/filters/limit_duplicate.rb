# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Reduce the duplicated events.
#
# This filter is used to limit the events which are duplicated in a peroid 
# to only one event, which means only allow the first event pass the filter, 
# and drop the following duplicated ones in a time period. Pay attention, usually
# there is a timestamp at the beginning of the log message, which will make 
# the log messages are not the same, just because the timestamp is not same, 
# so you need grok filter to get rid of the timestamp, by parsing an new filed used
# for duplicate checking.
#
# The config looks like this:
#
#     filter {
#       limit_duplicate {
#         limit_time_window => "30s"
#         duplicated_by => ["some field1", "some field2"]
#       }
#     }
class LogStash::Filters::LimitDuplicate < LogStash::Filters::Base

  config_name "limit_duplicate"
  milestone 1

  # The peroid time window of the logs should be droped by duplicated.
  config :limit_time_window, :validate => :string, :default => "30s"

  # The fields name used to check duplicated or not, by default is the message. 
  # It's a array, which means you can define it as ["field1","field2"], and it will check 
  # if both two fields' value are duplicated, then it considers the event as duplicated.
  config :duplicated_by, :validate => :array, :default => ["message"]

  public
  def register
    require "thread"
    require "rufus/scheduler"

    @duplicated_by = @duplicated_by.uniq.sort
    @mutex = Mutex.new
    @uniqueEventSet = Set.new
    @scheduler = Rufus::Scheduler.start_new
    @job = @scheduler.every @limit_time_window do
      @logger.info("Scheduler Activated")
      @mutex.synchronize{
        @uniqueEventSet.clear()
      }
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    
    @logger.info("do limit duplicate filter")
    if event == LogStash::SHUTDOWN
      @job.trigger()
      @job.unschedule()
      @logger.info("limit_duplicate filter thread shutdown.")
      return
    end

    uniqueFieldsValueArray = @duplicated_by.map do |item|
      event[item]
    end

    @mutex.synchronize{
      if (@uniqueEventSet.include?(uniqueFieldsValueArray))
        event.cancel
      else
        @uniqueEventSet << uniqueFieldsValueArray
      end
    }
  end # def filter

end #
