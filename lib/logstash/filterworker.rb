# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/plugin"
require "logstash/config/mixin"
require "stud/interval"

# TODO(sissel): Should this really be a 'plugin' ?
class LogStash::FilterWorker < LogStash::Plugin
  include Stud
  attr_accessor :logger
  attr_accessor :filters
  attr_reader	:after_filter

  Exceptions = [Exception]
  Exceptions << java.lang.Exception if RUBY_ENGINE == "jruby"

  def initialize(filters, input_queue, output_queue)
    @filters = filters
    @input_queue = input_queue
    @output_queue = output_queue
    @shutdown_requested = false
  end # def initialize

  #This block is called after each filter is done on an event. 
  #The filtered event and filter class name is passed to the block.
  #This could be used to add metrics in the future?
  def after_filter(&block)
    @after_filter = block
  end

  def run
    # TODO(sissel): Run a flusher thread for each plugin requesting flushes
    # > It seems reasonable that you could want a multiline filter to flush
    #   after 5 seconds, but want a metrics filter to flush every 10 or 60.

    # Set up the periodic flusher thread.
    @flusher = Thread.new { interval(5) { flusher } }

    while !@shutdown_requested && event = @input_queue.pop
      if event == LogStash::SHUTDOWN
        finished
        @input_queue << LogStash::SHUTDOWN # for the next filter thread
        return
      end

      filter(event)
    end # while @input_queue.pop
    finished
  end # def run

  def flusher
    events = []
    @filters.each do |filter|

      # Filter any events generated so far in this flush.
      events.each do |event|
        # TODO(sissel): watchdog on flush filtration?
        unless event.cancelled?
          filter.filter(event)
          @after_filter.call(event,filter) unless @after_filter.nil?
        end
      end

      # TODO(sissel): watchdog on flushes?
      if filter.respond_to?(:flush)
        flushed = filter.flush 
        events += flushed if !flushed.nil? && flushed.any?
      end
    end

    events.each do |event|
      @logger.debug? and @logger.debug("Pushing flushed events", :event => event)
      @output_queue.push(event) unless event.cancelled?
    end
  end # def flusher

  def teardown
    @shutdown_requested = true
  end

  def filter(original_event)
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
        begin
          update_watchdog(:event => event, :filter => filter)
          filter.execute(event) do |newevent|
            events << newevent
          end
        rescue *Exceptions => e
          @logger.warn("Exception during filter", :event => event,
                       :exception => $!, :backtrace => e.backtrace,
                       :filter => filter)
        ensure
          clear_watchdog
        end
        if event.cancelled?
          @logger.debug? and @logger.debug("Event cancelled", :event => event,
                                           :filter => filter.class)
          break
        end
        @after_filter.call(event,filter) unless @after_filter.nil?
      end # @filters.each

      @logger.debug? and @logger.debug("Event finished filtering", :event => event,
                                       :thread => Thread.current[:name])
      @output_queue.push(event) unless event.cancelled?
    end # events.each
  end # def filter
end # class LogStash::FilterWorker
