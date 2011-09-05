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
    #@filters.each do |filter|
      #filter.logger = @logger
      #filter.register
    #end

    while event = @input_queue.pop
      if event == LogStash::SHUTDOWN
        finished
        break
      end

      filter(event)
    end # while @input_queue.pop
  end

  def filter(original_event)
    # TODO(sissel): Handle exceptions? Retry? Drop it?

    # Make an 'events' array that filters can push onto if they
    # need to generate additional events based on the current event.
    # The 'split' filter does this, for example.
    events = [original_event]

    events.each do |event|
      @filters.each do |filter|
        # Filter can emit multiple events, like the 'split' event, so
        # give the input queue to dump generated events into.

        # TODO(sissel): This may require some refactoring later, I am not sure
        # this is the best approach. The goal is to allow filters to modify
        # the current event, but if necessary, create new events based on
        # this event.
        filter.filter(event) do |newevent|
          events << newevent
        end
        if event.cancelled?
          @logger.debug({:message => "Event cancelled",
                        :event => event,
                        :filter => filter.class,
          })
          break
        end
      end # @filters.each

      @logger.debug(["Event finished filtering", { :event => event, :thread => Thread.current[:name] }])
      @output_queue.push(event) unless event.cancelled?
    end # events.each 
  end # def filter
end # class LogStash::FilterWorker
