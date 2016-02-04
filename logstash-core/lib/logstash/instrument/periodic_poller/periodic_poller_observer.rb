# encoding: utf-8
module LogStash module Instrument module PeriodicPoller
  class PeriodicPollerObserver
    include LogStash::Util::Loggable
    
    def initialize(poller)
      @poller = poller
    end

    def update(time, result, exception)
      if exception
        logger.error("PeriodicPoller exception", :poller => @poller,
                     :result => result,
                     :exception => exception,
                     :executed_at => time)
      end
    end
  end
end; end; end
