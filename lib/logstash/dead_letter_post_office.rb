# encoding: utf-8

class LogStash::DeadLetterPostOffice

  def self.logger=(logger)
    @logger = logger
  end

  def self.logger
    @logger ||= Cabin::Channel.get(LogStash)
  end

  def self.destination=(destination)
    logger.info("Setting dead letter path", :path => destination.location)
    @destination = destination
  end

  def self.post(event)
    logger.warn("dead letter received!", :event => event.to_hash)
    event.tag("_dead_letter")
    event.cancel
    @destination.post(event)
  end

  module Destination

    class Base
      def location; end
      def post(event); end
    end

    class File < Base

      START_TIME = Time.now
      DUMP_PATH = ::File.join("/tmp", "dump.#{START_TIME.strftime("%Y%m%d%H%M%S")}.log")

      def initialize(path=DUMP_PATH)
        @path = path
        @file = ::File.open(path, "w")
      end

      def location
        @path
      end

      def post(event)
        @file.puts(event.to_json)
      end
    end
  end
end
