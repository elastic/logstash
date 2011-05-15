require "logstash/namespace"
require "logstash/logging"
require "logstash/plugin"
require "logstash/config/mixin"

# TODO(sissel): Should this really be a 'plugin' ?
class LogStash::FilterWorker < LogStash::Plugin
  attr_accessor :logger

  def initialize(filters, input_queue, output_queue)
    @filters = filters
    @input_queue = input_queue
    @output_queue = output_queue
  end # def initialize

  def run
    # for each thread.
    @filters.each do |filter|
      filter.logger = @logger
      filter.register
    end

    while event = @input_queue.pop
      if event == LogStash::SHUTDOWN
        finished
        break
      end

      # TODO(sissel): Handle exceptions? Retry? Drop it?
      @filters.each do |filter|
        filter.filter(event)
        if event.cancelled?
          @logger.debug({:message => "Event cancelled",
                        :event => event,
                        :filter => filter.class,
          })
          break
        end
      end # @filters.each

      @logger.debug(["Event finished filtering", event])
      @output_queue.push(event) unless event.cancelled?
    end # while @input_queue.pop
  end
end # class LogStash::FilterWorker
