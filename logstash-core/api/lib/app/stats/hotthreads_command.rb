# encoding: utf-8
require "app/command"
require 'monitoring'
require "socket"

class LogStash::Api::HotThreadsCommand < LogStash::Api::Command

  SKIPPED_THREADS = [ "Finalizer", "Reference Handler", "Signal Dispatcher" ]

  def run
    hash = JRMonitor.threads.generate
    report = "::: {#{hostname}} <br/> Hot threads at #{Time.now}, busiestThreads=#{hash.count}:"
    hash.each_pair do |thread_name, container|
      next if SKIPPED_THREADS.include?(thread_name)
      report << "<p> #{build_report(container)} </p>"
    end
    report
  end

  private

  def build_report(hash)
    thread_name, thread_path = hash["thread.name"].split(": ")
    report = <<-REPORT
       0.1% (#{hash["cpu.time"]}micros out of 500ms) cpu usage by #{hash["thread.state"]} thread named '#{thread_name}'
    REPORT
    report << "<br/> #{thread_path}<br/>" if thread_path
    report
  end

  def hostname
    Socket.gethostname
  end

end
