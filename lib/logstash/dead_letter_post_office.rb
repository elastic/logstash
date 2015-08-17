# encoding: utf-8

class LogStash::DeadLetterPostOffice

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Cabin::Channel.get(LogStash)
  end

  def self.destination=(destination)
    logger.info("Dead letter events will be sent to \"#{destination.location}\".")
    @destination = destination
  end

  def self.<<(events)
    events = [events] unless events.is_a?(Array)

    events.each do |event|
      logger.warn("dead letter received!", :event => event.to_hash)
      event.tag("_dead_letter")
      event.cancel
      @destination << event
    end
  end

  module Destination

    class Base
      def location; end
      def <<(event); end
    end

    class Stdout < Base
      def location
        STDOUT
      end

      def <<(event)
        puts event
      end
    end

    class File < Base

      START_TIME = Time.now
      DUMP_PATH = ::File.join("/tmp", "dump.#{START_TIME.strftime("%Y%m%d%H%M%S")}")

      def initialize(path=DUMP_PATH)
        @path = path
        @file = ::File.open(path, "w")
      end

      def location
        @path
      end

      def <<(event)
        @file.puts(event.to_json)
      end
    end
  end
end
