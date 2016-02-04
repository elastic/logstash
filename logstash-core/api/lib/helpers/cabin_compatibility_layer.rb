# encoding: utf-8

require "cabin/namespace"

module Cabin::Mixins::SinatraLogger

  def write(data, &block)
    self.publish(data, &block)
  end

end
