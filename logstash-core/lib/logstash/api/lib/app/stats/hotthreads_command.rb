# encoding: utf-8
require "app/command"
require 'monitoring'
require "socket"

class LogStash::Api::HotThreadsCommand < LogStash::Api::Command

  SKIPPED_THREADS = [ "Finalizer", "Reference Handler", "Signal Dispatcher" ].freeze

  def run(options={})
    top_count = options.fetch(:threads, 3)
    ignore    = options.fetch(:ignore_idle_threads, true)
    hash = JRMonitor.threads.generate
    report = "::: {#{hostname}} \n Hot threads at #{Time.now}, busiestThreads=#{top_count}:\n"
    i = 0
    hash.each_pair do |thread_name, container|
      break if i >= top_count
      if ignore
        next if SKIPPED_THREADS.include?(thread_name)
        next if thread_name.match(/Ruby-\d+-JIT-\d+/)
      end
      report << "#{build_report(container)} \n"
      i += 1
    end
    report
  end

  private

  def build_report(hash)
    thread_name, thread_path = hash["thread.name"].split(": ")
    report = "\t #{cpu_time(hash)} micros of cpu usage by #{hash["thread.state"]} thread named '#{thread_name}'\n"
    report << "\t\t #{thread_path}\n" if thread_path
    hash["thread.stacktrace"].each do |trace|
      report << "\t\t#{trace}\n"
    end
    report
  end

  def hostname
    Socket.gethostname
  end

  def cpu_time(hash)
    hash["cpu.time"] / 1000
  end

end
