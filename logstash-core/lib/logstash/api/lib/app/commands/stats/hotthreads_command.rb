# encoding: utf-8
require "app/command"
require 'monitoring'
require "socket"

class LogStash::Api::HotThreadsCommand < LogStash::Api::Command

  STACK_TRACES_SIZE_DEFAULT = 10.freeze

  def run(options={})
    filter = { :stacktrace_size => options.fetch(:stacktrace_size, STACK_TRACES_SIZE_DEFAULT) }
    hash   = JRMonitor.threads.generate(filter)
    ThreadDump.new(hash, self, options)
  end

  private

  class ThreadDump

    SKIPPED_THREADS             = [ "Finalizer", "Reference Handler", "Signal Dispatcher" ].freeze
    THREADS_COUNT_DEFAULT       = 10.freeze
    IGNORE_IDLE_THREADS_DEFAULT = true.freeze

    attr_reader :top_count, :ignore, :dump

    def initialize(dump, cmd, options={})
      @dump      = dump
      @options   = options
      @top_count = options.fetch(:threads, THREADS_COUNT_DEFAULT)
      @ignore    = options.fetch(:ignore_idle_threads, IGNORE_IDLE_THREADS_DEFAULT)
      @cmd       = cmd
    end

    def to_s
      hash = to_hash
      report =  "#{I18n.t("logstash.web_api.hot_threads.title", :hostname => hash[:hostname], :time => hash[:time], :top_count => top_count )} \n"
      hash[:threads].each do |thread|
        thread_report = ""
        thread_report = "\t #{I18n.t("logstash.web_api.hot_threads.thread_title", :percent_of_cpu_time => thread[:percent_of_cpu_time], :thread_state => thread[:state], :thread_name => thread[:name])} \n"
        thread_report = "\t #{thread[:percent_of_cpu_time]} % of of cpu usage by #{thread[:state]} thread named '#{thread[:name]}'\n"
        thread_report << "\t\t #{thread[:path]}\n" if thread[:path]
        thread[:traces].split("\n").each do |trace|
          thread_report << "#{trace}\n"
        end
        report << thread_report
      end
      report
    end

    def to_hash
      hash = { :hostname => hostname, :time => Time.now.iso8601, :busiest_threads => top_count, :threads => [] }
      each do |thread_name, _hash|
        thread_name, thread_path = _hash["thread.name"].split(": ")
        thread = { :name => thread_name,
                   :percent_of_cpu_time => cpu_time_as_percent(_hash),
                   :state => _hash["thread.state"]
        }
        thread[:path] = thread_path if thread_path
        traces = ""
        _hash["thread.stacktrace"].each do |trace|
          traces << "\t\t#{trace}\n"
        end
        thread[:traces] = traces unless traces.empty?
        hash[:threads] << thread
      end
      hash
    end

    private

    def each(&block)
      i=0
      dump.each_pair do |thread_name, _hash|
        break if i >= top_count
        if ignore
          next if SKIPPED_THREADS.include?(thread_name)
          next if thread_name.match(/Ruby-\d+-JIT-\d+/)
        end
        block.call(thread_name, _hash)
        i += 1
      end
    end

    def hostname
      @cmd.hostname
    end

    def cpu_time_as_percent(hash)
      (((cpu_time(hash) / @cmd.uptime * 1.0)*10000).to_i)/100.0
    end

    def cpu_time(hash)
      hash["cpu.time"] / 1000000.0
    end
  end

end
