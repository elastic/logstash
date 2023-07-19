# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

java_import 'org.logstash.instrument.reports.ThreadsReport'

class HotThreadsReport
  STRING_SEPARATOR_LENGTH = 80.freeze
  HOT_THREADS_STACK_TRACES_SIZE_DEFAULT = 50.freeze

  def initialize(cmd, options)
    @cmd = cmd
    filter = { 'stacktrace_size' => "#{options.fetch(:stacktrace_size, HOT_THREADS_STACK_TRACES_SIZE_DEFAULT)}" }
    @thread_dump = ::LogStash::Util::ThreadDump.new(options.merge(:dump => ThreadsReport.generate(filter)))
  end

  def to_s
    hash = to_hash[:hot_threads]
    report =  "#{I18n.t("logstash.web_api.hot_threads.title", :hostname => hash[:hostname], :time => hash[:time], :top_count => @thread_dump.top_count)} \n"
    report << '=' * STRING_SEPARATOR_LENGTH
    report << "\n"
    hash[:threads].each do |thread|
      line_str = I18n.t("logstash.web_api.hot_threads.thread_title",
        :percent_of_cpu_time => thread[:percent_of_cpu_time],
        :thread_state => thread[:state],
        :thread_name => thread[:name],
        :thread_id => thread[:thread_id])
      thread_report = "#{line_str} \n"
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
    @thread_dump.each do |_hash|
      thread_name, thread_path = _hash["thread.name"].split(": ")
      thread = { :name => thread_name,
                 :thread_id => _hash["thread.id"],
                 :percent_of_cpu_time => cpu_time_as_percent(_hash),
                 :state => _hash["thread.state"]
      }
      thread[:path] = thread_path if thread_path
      traces = []
      _hash["thread.stacktrace"].each do |trace|
        traces << trace
      end
      thread[:traces] = traces
      hash[:threads] << thread
    end
    { :hot_threads => hash }
  end

  def cpu_time_as_percent(hash)
    (((cpu_time(hash) / @cmd.uptime * 1.0) * 10000).to_i) / 100.0
  end

  def cpu_time(hash)
    hash["cpu.time"] / 1000000.0
  end
end
