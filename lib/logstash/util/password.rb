# encoding: utf-8
require "logstash/namespace"
require "logstash/util"

# This class exists to quietly wrap a password string so that, when printed or
# logged, you don't accidentally print the password itself.
class LogStash::Util::Password
  attr_reader :value

  public
  def initialize(password)
    @value = password
  end # def initialize

  public
  def to_s
    return "<password>"
  end # def to_s

  public
  def inspect
    return to_s
  end # def inspect
end # class LogStash::Util::Password

