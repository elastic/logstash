# encoding: utf-8
require "logstash/instrument/periodic_poller/cgroup"
require "spec_helper"

describe LogStash::Instrument::PeriodicPoller::Cgroup do
  subject { described_class }

  context ".are_cgroup_available?" do
    context "all the file exist" do
      before do
        allow(::File).to receive(:exist?).with(subject::PROC_SELF_CGROUP_FILE).and_return(true)
        allow(::Dir).to receive(:exist?).with(subject::PROC_CGROUP_CPU_DIR).and_return(true)
        allow(::Dir).to receive(:exist?).with(subject::PROC_CGROUP_CPUACCT_DIR).and_return(true)
      end

      it "returns true" do
        expect(subject.are_cgroup_available?).to be_truthy
      end
    end

    context "not all the file exist" do
      before do
        allow(::File).to receive(:exist?).with(subject::PROC_SELF_CGROUP_FILE).and_return(true)
        allow(::Dir).to receive(:exist?).with(subject::PROC_CGROUP_CPU_DIR).and_return(false)
        allow(::Dir).to receive(:exist?).with(subject::PROC_CGROUP_CPUACCT_DIR).and_return(true)
      end

      it "returns false" do
        expect(subject.are_cgroup_available?).to be_falsey
      end
    end
  end

  context ".control_groups" do
    let(:proc_self_cgroup_content) {
      %w(14:name=systemd,holaunlimited:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
13:pids:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
12:hugetlb:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
11:net_prio:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
10:perf_event:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
9:net_cls:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
8:freezer:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
7:devices:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
6:memory:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
5:blkio:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
4:cpuacct:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
3:cpu:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
2:cpuset:/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61
1:name=openrc:/docker) }

    before do
      allow(subject).to receive(:read_proc_self_cgroup_lines).and_return(proc_self_cgroup_content)
    end

    it "returns the control groups" do
      expect(subject.control_groups).to match({
        "name=systemd" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "holaunlimited" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "pids" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "hugetlb" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "net_prio" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "perf_event" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "net_cls" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "freezer" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "devices" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "memory" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "blkio" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "cpuacct" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "cpu" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "cpuset" => "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61",
        "name=openrc" => "/docker"
      })
    end
  end

  context ".get_all" do
    context "when we can retrieve the stats" do
      let(:cpuacct_control_group) { "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61" }
      let(:cpuacct_usage) { 1982 }
      let(:cpu_control_group) { "/docker/a10687343f90e97bbb1f7181bd065a42de96c40c4aa91764a9d526ea30475f61" }
      let(:cfs_period_micros) { 500 }
      let(:cfs_quota_micros) { 98 }
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
        allow(subject).to receive(:read_proc_self_cgroup_lines).and_return(proc_self_cgroup_content)
        allow(subject).to receive(:read_sys_fs_cgroup_cpuacct_cpu_stat).and_return(cpu_stat_file_content)

        allow(subject).to receive(:cgroup_cpuacct_usage_nanos).with(cpuacct_control_group).and_return(cpuacct_usage)
        allow(subject).to receive(:cgroup_cpu_fs_period_micros).with(cpu_control_group).and_return(cfs_period_micros)
        allow(subject).to receive(:cgroup_cpu_fs_quota_micros).with(cpu_control_group).and_return(cfs_quota_micros)
      end

      it "returns all the stats" do
        expect(subject.get_all).to match(
          :cpuacct => {
            :control_group => cpuacct_control_group,
            :usage_nanos => cpuacct_usage,
          },
          :cpu => {
            :control_group => cpu_control_group,
            :cfs_period_micros => cfs_period_micros,
            :cfs_quota_micros => cfs_quota_micros,
            :stat => {
                :number_of_elapsed_periods => cpu_stats_number_of_periods,
                :number_of_times_throttled => cpu_stats_number_of_time_throttled,
                :time_throttled_nanos => cpu_stats_time_throttled_nanos
            }
          }
        )
      end
    end

    context "when an exception is raised" do
      before do
        allow(subject).to receive(:control_groups).and_raise("Something went wrong")
      end

      it "returns nil" do
        expect(subject.get_all).to be_nil
      end
    end
  end
end
