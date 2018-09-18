# encoding: utf-8
require "logstash/instrument/periodic_poller/cgroup"
require "spec_helper"

LogStash::Logging::Logger::configure_logging("DEBUG")

module LogStash module Instrument module PeriodicPoller
describe "cgroup stats" do
  let(:relative_path) { "/docker/a1f61" }
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
  describe Cgroup::CGroupResources do
    subject { described_class.new }
    context "method: cgroup_available?" do
      context "resources exist" do
        before do
          allow(subject.cgroup_file).to receive(:exist?).and_return(true)
          allow(subject.cpu_dir).to receive(:exist?).and_return(true)
          allow(subject.cpuacct_dir).to receive(:exist?).and_return(true)
        end
        it "returns true" do
          expect(subject.cgroup_available?).to be_truthy
        end
      end
      context "resources do not exist" do
        subject { described_class.new }
        before do
          allow(subject.cgroup_file).to receive(:exist?).and_return(true)
          allow(subject.cpu_dir).to receive(:exist?).and_return(false)
          allow(subject.cpuacct_dir).to receive(:exist?).and_return(true)
        end
        it "returns false" do
          expect(subject.cgroup_available?).to be_falsey
        end
      end
    end

    context "method: controller_groups" do
      before do
        allow(subject).to receive(:read_lines).and_return(proc_self_cgroup_content)
      end

      it "returns the control groups" do
        controllers = subject.controller_groups
        # STDERR.puts(controllers.keys.inspect)
        controller = controllers["name=systemd"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/name=systemd")
        expect(controller.offset_path).to eq(relative_path)
        expect(controller.override).to be_a(Cgroup::NullOverride)

        controller = controllers["holaunlimited"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/holaunlimited")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["pids"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/pids")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["hugetlb"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/hugetlb")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["net_prio"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/net_prio")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["perf_event"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/perf_event")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["net_cls"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/net_cls")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["freezer"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/freezer")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["devices"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/devices")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["memory"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/memory")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["blkio"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/blkio")
        expect(controller.offset_path).to eq(relative_path)
        # ["", "", "", "", "", "cpuacct", "cpu", "", ""]

        controller = controllers["cpuacct"]
        expect(controller).to be_a(Cgroup::CpuAcctResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/cpuacct")
        expect(controller.offset_path).to eq(relative_path)
        expect(controller.override).to be_a(Cgroup::Override)
        expect(controller.override.nil?).to be_truthy

        controller = controllers["cpu"]
        expect(controller).to be_a(Cgroup::CpuResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/cpu")
        expect(controller.offset_path).to eq(relative_path)
        expect(controller.override).to be_a(Cgroup::Override)
        expect(controller.override.nil?).to be_truthy

        controller = controllers["cpuset"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/cpuset")
        expect(controller.offset_path).to eq(relative_path)

        controller = controllers["name=openrc"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/name=openrc")
        expect(controller.offset_path).to eq("/docker")
      end
    end

    context "method: controller_groups with override" do
      before do
        java.lang.System.setProperty("ls.cgroup.cpu.path.override", "/foo")
        java.lang.System.setProperty("ls.cgroup.cpuacct.path.override", "/bar")
        allow(subject).to receive(:read_lines).and_return(proc_self_cgroup_content)
      end
      after do
        java.lang.System.clearProperty("ls.cgroup.cpu.path.override")
        java.lang.System.clearProperty("ls.cgroup.cpuacct.path.override")
      end
      it "returns overridden control groups" do
        controllers = subject.controller_groups
        controller = controllers["cpuacct"]
        expect(controller).to be_a(Cgroup::CpuAcctResource)
        expect(controller.override.nil?).to be_falsey
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/cpuacct")
        expect(controller.offset_path).to eq("/bar")
        expect(controller.override).to be_a(Cgroup::Override)

        controller = controllers["cpu"]
        expect(controller).to be_a(Cgroup::CpuResource)
        expect(controller.override.nil?).to be_falsey
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/cpu")
        expect(controller.offset_path).to eq("/foo")
        expect(controller.override).to be_a(Cgroup::Override)

        controller = controllers["cpuset"]
        expect(controller).to be_a(Cgroup::UnhandledResource)
        expect(controller.base_path.to_path).to eq("/sys/fs/cgroup/cpuset")
        expect(controller.offset_path).to eq(relative_path)
      end
    end
  end

  describe Cgroup::CpuAcctResource do
    subject { described_class.new(Pathname.new("/sys/fs/foo"), Cgroup::Override.new("foo.bar"), "/bar") }
    describe "method: fill, without override" do
      let(:target) { Hash.new }
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(subject.base_path.to_path).to eq("/sys/fs/foo")
          expect(subject.offset_path).to eq("/bar")
          subject.fill(target)
          expect(target).to eq({:control_group=>"/bar", :usage_nanos=>-1})
        end
      end
    end
    describe "method: fill, with override" do
      before do
        java.lang.System.setProperty("foo.bar", "/quux")
      end
      after do
        java.lang.System.clearProperty("foo.bar")
      end
      let(:target) { Hash.new }
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(subject.base_path.to_path).to eq("/sys/fs/foo")
          expect(subject.offset_path).to eq("/quux")
          subject.fill(target)
          expect(target).to eq({:control_group=>"/quux", :usage_nanos=>-1})
        end
      end
    end
  end

  describe Cgroup::CpuResource do
    subject { described_class.new(Pathname.new("/sys/fs/foo"), Cgroup::Override.new("foo.bar"), "/bar") }
    describe "method: fill, without override" do
      let(:target) { Hash.new }
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(subject.base_path.to_path).to eq("/sys/fs/foo")
          expect(subject.offset_path).to eq("/bar")
          subject.fill(target)
          expect(target).to eq({:cfs_period_micros=>-1, :cfs_quota_micros=>-1, :control_group=>"/bar", :stat=>{:number_of_elapsed_periods=>-1, :number_of_times_throttled=>-1, :time_throttled_nanos=>-1}})
        end
      end
    end
    describe "method: fill, with override" do
      before do
        java.lang.System.setProperty("foo.bar", "/quux")
      end
      after do
        java.lang.System.clearProperty("foo.bar")
      end
      let(:target) { Hash.new }
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(subject.base_path.to_path).to eq("/sys/fs/foo")
          expect(subject.offset_path).to eq("/quux")
          subject.fill(target)
          expect(target).to eq({:cfs_period_micros=>-1, :cfs_quota_micros=>-1, :control_group=>"/quux", :stat=>{:number_of_elapsed_periods=>-1, :number_of_times_throttled=>-1, :time_throttled_nanos=>-1}})
        end
      end
    end
  end
  
  describe Cgroup do
    describe "class method: get_all" do
      let(:cpuacct_usage) { 1982 }
      let(:cfs_period_micros) { 500 }
      let(:cfs_quota_micros) { 98 }
      let(:cpu_stats_number_of_periods) { 1 }
      let(:cpu_stats_number_of_time_throttled) { 2 }
      let(:cpu_stats_time_throttled_nanos) { 3 }
      let(:override) { Cgroup::Override.new("foo.bar") }
      let(:cpu_stat_file_content) do
        ["nr_periods #{cpu_stats_number_of_periods}", "nr_throttled #{cpu_stats_number_of_time_throttled}", "throttled_time #{cpu_stats_time_throttled_nanos}"]
      end
      let(:cpu_controller)     { Cgroup::CpuResource.new("/sys/fs/cgroup/cpu", override, relative_path) }
      let(:cpuacct_controller) { Cgroup::CpuAcctResource.new("/sys/fs/cgroup/cpuacct", override, relative_path)}
      let(:cgroup_resources) { Cgroup::CGroupResources.new }
      before do
        allow(cpuacct_controller).to receive(:read_first_line).with("/sys/fs/cgroup/cpuacct#{relative_path}/cpuacct.usage").and_return(cpuacct_usage)
        allow(cpu_controller).to receive(:read_first_line).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_period_us").and_return(cfs_period_micros)
        allow(cpu_controller).to receive(:read_first_line).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_quota_us").and_return(cfs_quota_micros)
        allow(cpu_controller).to receive(:read_lines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.stat").and_return(cpu_stat_file_content)
        allow(cpuacct_controller).to receive(:exist?).and_return(true)
        allow(cpu_controller).to receive(:exist?).and_return(true)
        allow(cgroup_resources).to receive(:cgroup_available?).and_return(true)
        allow(cgroup_resources).to receive(:read_lines).and_return(proc_self_cgroup_content)

        allow(Cgroup::CpuResource).to receive(:new).and_return(cpu_controller)
        allow(Cgroup::CpuAcctResource).to receive(:new).and_return(cpuacct_controller)
      end
      it "returns all the stats" do
        expect(described_class.get_all(cgroup_resources)).to match(
          :cpuacct => {
            :control_group => relative_path,
            :usage_nanos => cpuacct_usage,
          },
          :cpu => {
            :control_group => relative_path,
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
      let(:cgroup_resources) { Cgroup::CGroupResources.new }
      before do
        allow(cgroup_resources).to receive(:cgroup_available?).and_return(true)
        allow(cgroup_resources).to receive(:controller_groups).and_raise("Something went wrong")
      end

      it "method: get_all returns nil" do
        expect(described_class.get_all(cgroup_resources)).to be_nil
      end
    end
  end
end
end end end