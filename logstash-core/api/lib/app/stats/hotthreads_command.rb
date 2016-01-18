# encoding: utf-8
require "app/command"
require 'monitoring'
require "socket"

class LogStash::Api::HotThreadsCommand < LogStash::Api::Command

  SKIPPED_THREADS = [ "Finalizer", "Reference Handler", "Signal Dispatcher" ]

  def run(options)
    top_count = options.fetch(:threads, 3)
    ignore    = options.fetch(:ignore_idle_threads, true)
    hash = JRMonitor.threads.generate
    report = "::: {#{hostname}} <br/> Hot threads at #{Time.now}, busiestThreads=#{top_count}:"
    i = 0
    hash.each_pair do |thread_name, container|
      break if i >= top_count
      if ignore
        next if SKIPPED_THREADS.include?(thread_name)
        next if thread_name.match(/Ruby-\d+-JIT-\d+/)
      end
      report << "<p> #{build_report(container)} </p>"
      i += 1
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
