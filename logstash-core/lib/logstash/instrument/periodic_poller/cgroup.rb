# encoding: utf-8
require "pathname"

# Logic from elasticsearch/core/src/main/java/org/elasticsearch/monitor/os/OsProbe.java
# Move to ruby to remove any existing dependency
module LogStash module Instrument module PeriodicPoller
  class Cgroup
    include LogStash::Util::Loggable
    class Override
      attr_reader :key, :value
      def initialize(key)
        @key = key
        @value = java.lang.System.getProperty(@key)
      end

      def nil?
        value.nil?
      end

      def override(other)
        nil? ? other : value
      end
    end

    class NullOverride
      def override(other)
        other
      end
    end

    ## `/proc/self/cgroup` contents look like this
    # 5:cpu,cpuacct:/
    # 4:cpuset:/
    # 2:net_cls,net_prio:/
    # 0::/user.slice/user-1000.slice/session-932.scope
    ## e.g. N:controller:/path-to-info
    # we find the controller and path
    # we skip the line without a controller e.g. 0::/path
    # we assume there are these symlinks:
    # `/sys/fs/cgroup/cpu` -> `/sys/fs/cgroup/cpu,cpuacct
    # `/sys/fs/cgroup/cpuacct` -> `/sys/fs/cgroup/cpu,cpuacct

    class CGroupResources
      attr_reader :cgroup_file, :cpu_dir, :cpuacct_dir
      attr_reader :cpu_path_override, :cpuacct_path_override
      attr_reader :controller_cpuacct, :controller_cpu

      CONTROL_GROUP_RE = Regexp.compile("\\d+:([^:,]+(?:,[^:,]+)?):(/.*)")
      CONTROLLER_SEPARATOR_RE = ","

      def initialize
        @cgroup_file = Pathname.new("/proc/self/cgroup")
        @cpuacct_dir = Pathname.new("/sys/fs/cgroup/cpuacct")
        @cpu_dir = Pathname.new("/sys/fs/cgroup/cpu")
        @cpu_path_override = Override.new("ls.cgroup.cpu.path.override")
        @cpuacct_path_override = Override.new("ls.cgroup.cpuacct.path.override")
        @controller_cpuacct = "cpuacct"
        @controller_cpu = "cpu"
      end

      def cgroup_available?
        # don't cache to ivar, in case the files are mounted after logstash starts??
        @cgroup_file.exist? && @cpuacct_dir.exist? && @cpu_dir.exist?
      end

      def controller_groups
        response = {}
        read_lines.each do |line|
          matches = CONTROL_GROUP_RE.match(line)
          next if matches.nil?
          # multiples controls, same hierarchy
          controllers = matches[1].split(CONTROLLER_SEPARATOR_RE)
          controllers.each_with_object(response) do |controller|
            case controller
            when @controller_cpu
              response[controller] = CpuResource.new(@cpu_dir, @cpu_path_override, matches[2])
            when @controller_cpuacct
              response[controller] = CpuAcctResource.new(@cpuacct_dir, @cpuacct_path_override, matches[2])
            else
              response[controller] = UnhandledResource.new(Pathname.new("/sys/fs/cgroup").join(controller), NullOverride.new, matches[2])
            end
          end
        end
        response
      end

      def read_lines
        IO.readlines(@cgroup_file)
      end
    end

    module ControllerResource
      attr_reader :base_path, :override, :offset_path
      def initialize(base_path, override, offset_path)
        @base_path = base_path
        # override is needed here for the logging statements
        # so we do the override here and not in the caller
        @override = override
        @offset_path = @override.override(offset_path)
      end
      def check_path(path, not_found_value)
        if exist?(path)
          yield
        else
          message = "File #{path} cannot be found, "
          if override.nil?
            message.concat("try providing an override '#{override.key}' in the Logstash JAVA_OPTS environment variable")
          else
            message.concat("even though the '#{override.key}' override is: '#{override.value}'")
          end
          logger.debug(message)
          not_found_value
        end
      end
      def exist?(path)
        ::File.exist?(path)
      end
      def read_first_line(path)
        read_lines(path).first
      end
      def read_lines(path)
        IO.readlines(path)
      end
      def join(filename)
        ::File.join(@base_path, @offset_path, filename)
      end
    end

    class CpuAcctResource
      include LogStash::Util::Loggable
      include ControllerResource
      def fill(hash)
        hash[:control_group] = offset_path
        hash[:usage_nanos] = cpuacct_usage
      end
      private
      def cpuacct_usage
        path = join("cpuacct.usage")
        check_path(path, -1) { read_first_line(path).to_i }
      end
    end

    class CpuResource
      include LogStash::Util::Loggable
      include ControllerResource
      def fill(hash)
        hash[:control_group] = offset_path
        hash[:cfs_period_micros] = cfs_period_us
        hash[:cfs_quota_micros] = cfs_quota_us

        cpu_stats = build_cpu_stats

        hash[:stat] = {
         :number_of_elapsed_periods => cpu_stats.number_of_elapsed_periods,
         :number_of_times_throttled => cpu_stats.number_of_times_throttled,
         :time_throttled_nanos => cpu_stats.time_throttled_nanos
        }
      end
      private
      def cfs_period_us
        path = join("cpu.cfs_period_us")
        check_path(path, -1) { read_first_line(path).to_i }
      end
      def cfs_quota_us
        path = join("cpu.cfs_quota_us")
        check_path(path, -1) { read_first_line(path).to_i }
      end
      def build_cpu_stats
        path = join("cpu.stat")
        not_found = ["nr_periods -1", "nr_throttled -1", "throttled_time -1"]
        lines = check_path(path, not_found) { read_lines(path) }

        number_of_elapsed_periods = -1
        number_of_times_throttled = -1
        time_throttled_nanos = -1

        lines.each do |line|
          fields = line.split(/\s+/)
          case fields.first
          when "nr_periods" then number_of_elapsed_periods = fields[1].to_i
          when "nr_throttled" then number_of_times_throttled = fields[1].to_i
          when "throttled_time" then time_throttled_nanos = fields[1].to_i
          end
        end

        CpuStats.new(number_of_elapsed_periods, number_of_times_throttled, time_throttled_nanos)
      end
    end

    class UnhandledResource
      include LogStash::Util::Loggable
      include ControllerResource
    end

    class CpuStats
      attr_reader :number_of_elapsed_periods, :number_of_times_throttled, :time_throttled_nanos

      def initialize(number_of_elapsed_periods, number_of_times_throttled, time_throttled_nanos)
        @number_of_elapsed_periods = number_of_elapsed_periods
        @number_of_times_throttled = number_of_times_throttled
        @time_throttled_nanos = time_throttled_nanos
      end
    end

    class << self
      def get_all(resources = CGroupResources.new)
        unless resources.cgroup_available?
          files = [resources.cgroup_file, resources.cpu_dir, resources.cpuacct_dir]
          logger.debug("One or more required cgroup files or directories not found: #{files.join(', ')}")
          return
        end

        groups = resources.controller_groups

        if groups.empty?
          logger.debug("The main cgroup file did not have any controllers: #{resources.cgroup_file}")
          return
        end

        cpuacct_controller = groups[resources.controller_cpuacct]
        cpu_controller = groups[resources.controller_cpu]

        cgroups_stats = {
         :cpuacct => {},
         :cpu => {}
        }
        cpuacct_controller.fill(cgroups_stats[:cpuacct])
        cpu_controller.fill(cgroups_stats[:cpu])
        cgroups_stats
      rescue => e
        logger.debug("Error, cannot retrieve cgroups information", :exception => e.class.name, :message => e.message, :backtrace => e.backtrace.take(4)) if logger.debug?
        nil
      end

      def get
        get_all
      end
    end
  end
end end end
