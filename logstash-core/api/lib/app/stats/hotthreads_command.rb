# encoding: utf-8
require "app/command"
require 'monitoring'

class LogStash::Api::HotThreadsCommand < LogStash::Api::Command

  def run
    generate
  end

  def generate
    JRMonitor.threads.generate
  end
end
