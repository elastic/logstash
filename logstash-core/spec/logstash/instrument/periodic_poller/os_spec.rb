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

require "logstash/instrument/periodic_poller/os"
require "logstash/instrument/collector"

describe LogStash::Instrument::PeriodicPoller::Os do
  let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }

  context "recorded cgroup metrics (mocked cgroup env)" do
    subject { described_class.new(metric, {})}

    let(:snapshot_store) { metric.collector.snapshot_metric.metric_store }
    let(:os_metrics) { snapshot_store.get_shallow(:os) }

    let(:relative_path) { "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61" }
    let(:proc_self_cgroup_content) do
      %W(14:name=systemd,holaunlimited:#{relative_path}
          13:pids:#{relative_path}
          12:hugetlb:#{relative_path}
          11:net_prio:#{relative_path}
          10:perf_event:#{relative_path}
          9:net_cls:#{relative_path}
          8:freezer:#{relative_path}
          7:devices:#{relative_path}
          6:memory:#{relative_path}
          5:blkio:#{relative_path}
          4:cpuacct:#{relative_path}
          3:cpu:#{relative_path}
          2:cpuset:#{relative_path}
          1:name=openrc:/docker
          0::/docker)
    end

    let(:cpuacct_usage) { 1982 }
    let(:cpu_period_micros) { 500 }
    let(:cpu_quota_micros) { 98 }
    let(:cpu_stats_number_of_periods) { 1 }
    let(:cpu_stats_number_of_time_throttled) { 2 }
    let(:cpu_stats_time_throttled_nanos) { 3 }

    let(:cpu_stat_file_content) do
      ["nr_periods #{cpu_stats_number_of_periods}", "nr_throttled #{cpu_stats_number_of_time_throttled}", "throttled_time #{cpu_stats_time_throttled_nanos}"]
    end

    before do
      allow(::File).to receive(:exist?).and_return(true)
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpuacct#{relative_path}/cpuacct.usage").and_return([cpuacct_usage])
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_period_us").and_return([cpu_period_micros])
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_quota_us").and_return([cpu_quota_micros])
      allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.stat").and_return(cpu_stat_file_content)
      allow(IO).to receive(:readlines).with("/proc/self/cgroup").and_return(proc_self_cgroup_content)

      subject.collect
    end

    def mval(*metric_path)
      metric_path.reduce(os_metrics) {|acc, k| acc[k]}.value
    end

    it "should have a value for #{[:cgroup, :cpuacc, :control_group]} that is a String" do
      expect(mval(:cgroup, :cpuacct, :control_group)).to be_a(String)
    end

    it "should have a value for #{[:cgroup, :cpu, :control_group]} that is a String" do
      expect(mval(:cgroup, :cpu, :control_group)).to be_a(String)
    end

    [
      [:cgroup, :cpuacct, :usage_nanos],
      [:cgroup, :cpu, :cfs_period_micros],
      [:cgroup, :cpu, :cfs_quota_micros],
      [:cgroup, :cpu, :stat, :number_of_elapsed_periods],
      [:cgroup, :cpu, :stat, :number_of_times_throttled],
      [:cgroup, :cpu, :stat, :time_throttled_nanos]
    ].each do |path|
      path = Array(path)
      it "should have a value for #{path} that is Numeric" do
        expect(mval(*path)).to be_a(Numeric)
      end
    end
  end
end
