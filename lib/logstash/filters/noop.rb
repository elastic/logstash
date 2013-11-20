# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# No-op filter. This is used generally for internal/dev testing.
class LogStash::Filters::NOOP < LogStash::Filters::Base
  config_name "noop"
  milestone 2

  public
  def register
    # Nothing
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    # Nothing to do
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::NOOP
