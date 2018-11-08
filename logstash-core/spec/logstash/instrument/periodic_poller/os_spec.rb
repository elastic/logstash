# encoding: utf-8
require "logstash/instrument/periodic_poller/os"
require "logstash/instrument/collector"

describe LogStash::Instrument::PeriodicPoller::Os do
  let(:metric) { LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new) }

  context "recorded cgroup metrics (mocked cgroup env)" do
    subject { described_class.new(metric, {})}

    let(:snapshot_store) { metric.collector.snapshot_metric.metric_store }
    let(:os_metrics) { snapshot_store.get_shallow(:os) }

    let(:cpuacct_control_group) { "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61" }
    let(:cpuacct_usage) { 1982 }
    let(:cpu_control_group) { "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61" }
    let(:cpu_period_micros) { 500 }
    let(:cpu_quota_micros) { 98 }
    let(:cpu_stats_number_of_periods) { 1 }
    let(:cpu_stats_number_of_time_throttled) { 2 }
    let(:cpu_stats_time_throttled_nanos) { 3 }
    let(:proc_self_cgroup_content) {
      %W(14:name=systemd,holaunlimited:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
13:pids:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
12:hugetlb:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
11:net_prio:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
10:perf_event:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
9:net_cls:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
8:freezer:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
7:devices:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
6:memory:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
5:blkio:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
4:cpuacct:#{cpuacct_control_group}
3:cpu:#{cpu_control_group}
2:cpuset:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
1:name=openrc:/docker) }
    let(:cpu_stat_file_content) {
      [
        "nr_periods #{cpu_stats_number_of_periods}",
        "nr_throttled #{cpu_stats_number_of_time_throttled}",
        "throttled_time #{cpu_stats_time_throttled_nanos}"
      ]
    }

    before do
      allow(LogStash::Instrument::PeriodicPoller::Cgroup).to receive(:are_cgroup_available?).and_return(true)

      allow(LogStash::Instrument::PeriodicPoller::Cgroup).to receive(:read_proc_self_cgroup_lines).and_return(proc_self_cgroup_content)
      allow(LogStash::Instrument::PeriodicPoller::Cgroup).to receive(:read_sys_fs_cgroup_cpuacct_cpu_stat).and_return(cpu_stat_file_content)

      allow(LogStash::Instrument::PeriodicPoller::Cgroup).to receive(:cgroup_cpuacct_usage_nanos).with(cpuacct_control_group).and_return(cpuacct_usage)
      allow(LogStash::Instrument::PeriodicPoller::Cgroup).to receive(:cgroup_cpu_fs_period_micros).with(cpu_control_group).and_return(cpu_period_micros)
      allow(LogStash::Instrument::PeriodicPoller::Cgroup).to receive(:cgroup_cpu_fs_quota_micros).with(cpu_control_group).and_return(cpu_quota_micros)

      subject.collect
    end

    def mval(*metric_path)
      metric_path.reduce(os_metrics) {|acc,k| acc[k]}.value
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
