# encoding: utf-8
require "logstash/outputs/base"

class DummyOutput < LogStash::Outputs::Base
  config_name "dummyoutput"
  milestone 2

  attr_reader :num_closes, :events

  def initialize(params={})
    super
    @num_closes = 0
    @events = []
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
