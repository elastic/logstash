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
#         duplicated_by => "some field"
#       }
#     }
class LogStash::Filters::LimitDuplicate < LogStash::Filters::Base

  config_name "limit_duplicate"
  milestone 1

  # The peroid time window of the logs should be droped by duplicated.
  config :limit_time_window, :validate => :string, :default => "30s"

  # The field name used to check duplicated or not, by default is the log message.
  config :duplicated_by, :validate => :string, :default => "message"

  public
  def register
    require "thread"
    require "rufus/scheduler"

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

    uniqueField = event[@duplicated_by]
    @mutex.synchronize{
      if (@uniqueEventSet.include?(uniqueField))
        event.cancel
      else
        @uniqueEventSet<<uniqueField
      end
    }
  end # def filter

end #
