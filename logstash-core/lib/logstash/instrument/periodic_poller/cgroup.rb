# encoding: utf-8
require "pathname"
require "logstash/util/loggable"

# Logic from elasticsearch/core/src/main/java/org/elasticsearch/monitor/os/OsProbe.java
# Move to ruby to remove any existing dependency
module LogStash module Instrument module PeriodicPoller
  class Cgroup
    include LogStash::Util::Loggable

    CONTROL_GROUP_RE = Regexp.compile("\\d+:([^:,]+(?:,[^:,]+)?):(/.*)");
    CONTROLLER_SEPARATOR_RE = ","

    PROC_SELF_CGROUP_FILE = Pathname.new("/proc/self/cgroup")
    PROC_CGROUP_CPU_DIR = Pathname.new("/sys/fs/cgroup/cpu")
    PROC_CGROUP_CPUACCT_DIR = Pathname.new("/sys/fs/cgroup/cpuacct")

    GROUP_CPUACCT = "cpuacct"
    CPUACCT_USAGE_FILE = "cpuacct.usage"

    GROUP_CPU = "cpu"
    CPU_FS_PERIOD_US_FILE = "cpu.cfs_period_us"
    CPU_FS_QUOTA_US_FILE = "cpu.cfs_quota_us"

    CPU_STATS_FILE = "cpu.stat"

    class << self
      def are_cgroup_available?
        [::File.exist?(PROC_SELF_CGROUP_FILE),
         Dir.exist?(PROC_CGROUP_CPU_DIR),
         Dir.exist?(PROC_CGROUP_CPUACCT_DIR)].all?
      end

      def control_groups
        response = {}

        read_proc_self_cgroup_lines.each do |line|
          matches = CONTROL_GROUP_RE.match(line)
          # multiples controls, same hierarchy
          controllers = matches[1].split(CONTROLLER_SEPARATOR_RE)
          controllers.each_with_object(response) { |controller| response[controller] = matches[2] }
        end

        response
      end

      def read_first_line(path)
        IO.readlines(path).first
      end

      def cgroup_cpuacct_usage_nanos(control_group)
        read_first_line(::File.join(PROC_CGROUP_CPUACCT_DIR, control_group, CPUACCT_USAGE_FILE)).to_i
      end

      def cgroup_cpu_fs_period_micros(control_group)
        read_first_line(::File.join(PROC_CGROUP_CPUACCT_DIR, control_group, CPU_FS_PERIOD_US_FILE)).to_i
      end

      def cgroup_cpu_fs_quota_micros(control_group)
        read_first_line(::File.join(PROC_CGROUP_CPUACCT_DIR, control_group,  CPU_FS_QUOTA_US_FILE)).to_i
      end

      def read_proc_self_cgroup_lines
        IO.readlines(PROC_SELF_CGROUP_FILE)
      end

      class CpuStats
        attr_reader :number_of_elapsed_periods, :number_of_times_throttled, :time_throttled_nanos

        def initialize(number_of_elapsed_periods, number_of_times_throttled, time_throttled_nanos)
          @number_of_elapsed_periods = number_of_elapsed_periods
          @number_of_times_throttled = number_of_times_throttled
          @time_throttled_nanos = time_throttled_nanos
        end
      end

      def read_sys_fs_cgroup_cpuacct_cpu_stat(control_group)
        IO.readlines(::File.join(PROC_CGROUP_CPU_DIR, control_group, CPU_STATS_FILE))
      end

      def cgroup_cpuacct_cpu_stat(control_group)
        lines = read_sys_fs_cgroup_cpuacct_cpu_stat(control_group);

        number_of_elapsed_periods = -1;
        number_of_times_throttled = -1;
        time_throttled_nanos = -1;

        lines.each do |line|
          fields = line.split(/\s+/)
          case fields.first
          when "nr_periods" then number_of_elapsed_periods = fields[1].to_i
          when "nr_throttled" then number_of_times_throttled= fields[1].to_i
          when "throttled_time" then time_throttled_nanos = fields[1].to_i
          end
        end

        CpuStats.new(number_of_elapsed_periods, number_of_times_throttled, time_throttled_nanos)
      end

      def get_all
       groups = control_groups
       return if groups.empty?

       cgroups_stats = {
         :cpuacct => {},
         :cpu => {}
       }

       cpuacct_group = groups[GROUP_CPUACCT]
       cgroups_stats[:cpuacct][:control_group] = cpuacct_group
       cgroups_stats[:cpuacct][:usage_nanos] = cgroup_cpuacct_usage_nanos(cpuacct_group)

       cpu_group = groups[GROUP_CPU]
       cgroups_stats[:cpu][:control_group] = cpu_group
       cgroups_stats[:cpu][:cfs_period_micros] = cgroup_cpu_fs_period_micros(cpu_group)
       cgroups_stats[:cpu][:cfs_quota_micros] = cgroup_cpu_fs_quota_micros(cpu_group)

       cpu_stats = cgroup_cpuacct_cpu_stat(cpu_group)

       cgroups_stats[:cpu][:stat] = {
         :number_of_elapsed_periods => cpu_stats.number_of_elapsed_periods,
         :number_of_times_throttled => cpu_stats.number_of_times_throttled,
         :time_throttled_nanos => cpu_stats.time_throttled_nanos
       }

       cgroups_stats
      rescue => e
        logger.debug("Error, cannot retrieve cgroups information", :exception => e.class.name, :message => e.message) if logger.debug?
        nil
      end

      def get
        are_cgroup_available? ? get_all : nil
      end
    end
  end
end end end
