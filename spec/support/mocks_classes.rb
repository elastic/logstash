# encoding: utf-8
require "logstash/outputs/base"
require "thread"

module LogStash module Outputs
  class DummyOutput < LogStash::Outputs::Base
    config_name "dummyoutput"
    milestone 2

    attr_reader :num_closes, :events

    def initialize(params={})
      super
      @num_closes = 0
      @events = Queue.new
    end

    def register
    end

    def receive(event)
      @events << event
    end

    def close
      @num_closes = 1
    end
  end

  class DummyOutputWithEventsArray < LogStash::Outputs::Base
    config_name "dummyoutput2"
    milestone 2

    attr_reader :events

    def initialize(params={})
      super
      @events = []
    end

    def register
    end

    def receive(event)
      @events << event
    end

    def close
    end
  end

  class DroppingDummyOutput < LogStash::Outputs::Base
    config_name "droppingdummyoutput"
    milestone 2

    attr_reader :num_closes

    def initialize(params={})
      super
      @num_closes = 0
      @events_received = Concurrent::AtomicFixnum.new(0)
    end

    def register
    end

    def receive(event)
      @events_received.increment
    end

    def events_received
      @events_received.value
    end

    def close
      @num_closes = 1
    end
  end
end end
