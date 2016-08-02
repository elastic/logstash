# encoding: utf-8
module LogStash module Docgen module Util
  def self.time_execution(&block)
    started_at = Time.now
    result = block.call
    puts "Execution took: #{Time.now - started_at}s"
    return result
  end

  def self.red(text)
    "\e[31m#{text}\e[0m"
  end

  def self.green(text)
    "\e[32m#{text}\e[0m"
  end

  def self.yellow(text)
    "\e[33m#{text}\e[0m"
  end
end end end
