# encoding: utf-8
module LogStash module Instrument module Reporter
  class Base
    def initialize(collector)
      collector.add_observer(self)
    end

    def update(time, snapshot)
      raise NotImplementedError, "The reporter need to implement `#update(time, snapshot)` method"
    end
  end
end; end; end
