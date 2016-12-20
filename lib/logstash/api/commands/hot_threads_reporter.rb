# encoding: utf-8

class HotThreadsReport
  STRING_SEPARATOR_LENGTH = 80.freeze
  HOT_THREADS_STACK_TRACES_SIZE_DEFAULT = 10.freeze

  def initialize(cmd, options)
    @cmd = cmd
    filter = { :stacktrace_size => options.fetch(:stacktrace_size, HOT_THREADS_STACK_TRACES_SIZE_DEFAULT) }
    jr_dump = JRMonitor.threads.generate(filter)
    @thread_dump = ::LogStash::Util::ThreadDump.new(options.merge(:dump => jr_dump))
  end

  def to_s
    hash = to_hash[:hot_threads]
    report =  "#{I18n.t("logstash.web_api.hot_threads.title", :hostname => hash[:hostname], :time => hash[:time], :top_count => @thread_dump.top_count )} \n"
    report << '=' * STRING_SEPARATOR_LENGTH
    report << "\n"
    hash[:threads].each do |thread|
      thread_report = "#{I18n.t("logstash.web_api.hot_threads.thread_title", :percent_of_cpu_time => thread[:percent_of_cpu_time], :thread_state => thread[:state], :thread_name => thread[:name])} \n"
      thread_report << "#{thread[:path]}\n" if thread[:path]
      thread[:traces].each do |trace|
        thread_report << "\t#{trace}\n"
      end
      report << thread_report
      report << '-' * STRING_SEPARATOR_LENGTH
      report << "\n"
    end
    report
  end

  def to_hash
    hash = { :time => Time.now.iso8601, :busiest_threads => @thread_dump.top_count, :threads => [] }
    @thread_dump.each do |thread_name, _hash|
      thread_name, thread_path = _hash["thread.name"].split(": ")
      thread = { :name => thread_name,
                 :percent_of_cpu_time => cpu_time_as_percent(_hash),
                 :state => _hash["thread.state"]
      }
      thread[:path] = thread_path if thread_path
      traces = []
      _hash["thread.stacktrace"].each do |trace|
        traces << trace
      end
      thread[:traces] = traces unless traces.empty?
      hash[:threads] << thread
    end
    { :hot_threads => hash }
  end

  def cpu_time_as_percent(hash)
    (((cpu_time(hash) / @cmd.uptime * 1.0)*10000).to_i)/100.0
  end

  def cpu_time(hash)
    hash["cpu.time"] / 1000000.0
  end
end
