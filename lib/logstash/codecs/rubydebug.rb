# encoding: utf-8
require "logstash/codecs/base"

# The rubydebug codec will output your Logstash event data using
# the Ruby Awesome Print library.
#
class LogStash::Codecs::RubyDebug < LogStash::Codecs::Base
  config_name "rubydebug"
  milestone 3

  def register
    require "ap"
  end

  public
  def decode(data)
    raise "Not implemented"
  end # def decode

  public
  def encode(event)
    @on_event.call(event.to_hash.awesome_inspect + NL)
  end # def encode

end # class LogStash::Codecs::Dots
