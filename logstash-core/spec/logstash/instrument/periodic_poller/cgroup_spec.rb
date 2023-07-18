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

require "logstash/instrument/periodic_poller/cgroup"
require "spec_helper"

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
    subject(:cgroup_resources) { described_class.new }
    context "method: cgroup_available?" do
      context "resources exist" do
        before do
          allow(::File).to receive(:exist?).and_return(true)
        end
        it "returns true" do
          expect(cgroup_resources.cgroup_available?).to be_truthy
        end
      end
      context "resources do not exist" do
        subject { described_class.new }
        before do
          allow(::File).to receive(:exist?).and_return(true)
          allow(::File).to receive(:exist?).with("/proc/self/cgroup").and_return(false)
        end
        it "returns false" do
          expect(cgroup_resources.cgroup_available?).to be_falsey
        end
      end
    end

    context "method: controller_groups" do
      before do
        allow(IO).to receive(:readlines).with("/proc/self/cgroup").and_return(proc_self_cgroup_content)
      end

      it "returns the control groups" do
        controllers = cgroup_resources.controller_groups

        controller = controllers["cpuacct"]
        expect(controller).to be_a(Cgroup::CpuAcctResource)
        expect(controller.base_path).to eq("/sys/fs/cgroup/cpuacct")
        expect(controller.offset_path).to eq(relative_path)
        expect(controller.override).to be_a(Cgroup::Override)
        expect(controller.override.nil?).to be_truthy

        controller = controllers["cpu"]
        expect(controller).to be_a(Cgroup::CpuResource)
        expect(controller.base_path).to eq("/sys/fs/cgroup/cpu")
        expect(controller.offset_path).to eq(relative_path)
        expect(controller.override).to be_a(Cgroup::Override)
        expect(controller.override.nil?).to be_truthy

        controller = controllers["name=systemd"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("name=systemd")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["holaunlimited"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("holaunlimited")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["pids"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("pids")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["hugetlb"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("hugetlb")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["net_prio"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("net_prio")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["perf_event"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("perf_event")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["net_cls"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("net_cls")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["freezer"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("freezer")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["devices"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("devices")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["memory"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("memory")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["blkio"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("blkio")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["cpuset"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("cpuset")
        expect(controller.original_path).to eq(relative_path)

        controller = controllers["name=openrc"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("name=openrc")
        expect(controller.original_path).to eq("/docker")
      end
    end

    context "method: controller_groups with override" do
      before do
        java.lang.System.setProperty("ls.cgroup.cpu.path.override", "/foo")
        java.lang.System.setProperty("ls.cgroup.cpuacct.path.override", "/bar")
        allow(IO).to receive(:readlines).with("/proc/self/cgroup").and_return(proc_self_cgroup_content)
      end
      after do
        java.lang.System.clearProperty("ls.cgroup.cpu.path.override")
        java.lang.System.clearProperty("ls.cgroup.cpuacct.path.override")
      end
      it "returns overridden control groups" do
        controllers = cgroup_resources.controller_groups
        controller = controllers["cpuacct"]
        expect(controller).to be_a(Cgroup::CpuAcctResource)
        expect(controller.override.nil?).to be_falsey
        expect(controller.base_path).to eq("/sys/fs/cgroup/cpuacct")
        expect(controller.offset_path).to eq("/bar")
        expect(controller.override).to be_a(Cgroup::Override)

        controller = controllers["cpu"]
        expect(controller).to be_a(Cgroup::CpuResource)
        expect(controller.override.nil?).to be_falsey
        expect(controller.base_path).to eq("/sys/fs/cgroup/cpu")
        expect(controller.offset_path).to eq("/foo")
        expect(controller.override).to be_a(Cgroup::Override)

        controller = controllers["cpuset"]
        expect(controller).to be_a(Cgroup::UnimplementedResource)
        expect(controller.controller).to eq("cpuset")
        expect(controller.original_path).to eq(relative_path)
      end
    end
  end

  describe Cgroup::CpuAcctResource do
    subject(:cpuacct_resource) { described_class.new("/bar") }
    describe "method: to_hash, without override" do
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(cpuacct_resource.base_path).to eq("/sys/fs/cgroup/cpuacct")
          expect(cpuacct_resource.offset_path).to eq("/bar")
          expect(cpuacct_resource.to_hash).to eq({:control_group => "/bar", :usage_nanos => -1})
        end
      end
    end
    describe "method: to_hash, with override" do
      before do
        java.lang.System.setProperty("ls.cgroup.cpuacct.path.override", "/quux")
      end
      after do
        java.lang.System.clearProperty("ls.cgroup.cpuacct.path.override")
      end
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(cpuacct_resource.base_path).to eq("/sys/fs/cgroup/cpuacct")
          expect(cpuacct_resource.offset_path).to eq("/quux")
          expect(cpuacct_resource.to_hash).to eq({:control_group => "/quux", :usage_nanos => -1})
        end
      end
    end
  end

  describe Cgroup::CpuResource do
    subject(:cpu_resource) { described_class.new("/bar") }
    describe "method: fill, without override" do
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(cpu_resource.base_path).to eq("/sys/fs/cgroup/cpu")
          expect(cpu_resource.offset_path).to eq("/bar")
          expect(cpu_resource.to_hash).to eq({:cfs_period_micros => -1, :cfs_quota_micros => -1, :control_group => "/bar", :stat => {:number_of_elapsed_periods => -1, :number_of_times_throttled => -1, :time_throttled_nanos => -1}})
        end
      end
    end
    describe "method: fill, with override" do
      before do
        java.lang.System.setProperty("ls.cgroup.cpu.path.override", "/quux")
      end
      after do
        java.lang.System.clearProperty("ls.cgroup.cpu.path.override")
      end
      let(:target) { Hash.new }
      context "when the files cannot be found" do
        it "fills in the hash with minus one" do
          expect(cpu_resource.base_path).to eq("/sys/fs/cgroup/cpu")
          expect(cpu_resource.offset_path).to eq("/quux")
          expect(cpu_resource.to_hash).to eq({:cfs_period_micros => -1, :cfs_quota_micros => -1, :control_group => "/quux", :stat => {:number_of_elapsed_periods => -1, :number_of_times_throttled => -1, :time_throttled_nanos => -1}})
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
      let(:cpu_stat_file_content) do
        ["nr_periods #{cpu_stats_number_of_periods}", "nr_throttled #{cpu_stats_number_of_time_throttled}", "throttled_time #{cpu_stats_time_throttled_nanos}"]
      end
      before do
        allow(::File).to receive(:exist?).and_return(true)
        allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpuacct#{relative_path}/cpuacct.usage").and_return([cpuacct_usage])
        allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_period_us").and_return([cfs_period_micros])
        allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.cfs_quota_us").and_return([cfs_quota_micros])
        allow(IO).to receive(:readlines).with("/sys/fs/cgroup/cpu#{relative_path}/cpu.stat").and_return(cpu_stat_file_content)
        allow(IO).to receive(:readlines).with("/proc/self/cgroup").and_return(proc_self_cgroup_content)
      end
      it "returns all the stats" do
        expect(described_class.get_all).to match(
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
      before do
        allow(::File).to receive(:exist?).and_return(true)
        allow(Cgroup::CGROUP_RESOURCES).to receive(:controller_groups).and_raise("Something went wrong")
      end

      it "method: get_all returns nil" do
        expect(described_class.get_all).to be_nil
      end
    end
  end
end
end end end
