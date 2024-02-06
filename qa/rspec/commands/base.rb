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

require 'tempfile'
require 'open3'
require_relative "system_helpers"

LS_BUILD_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'build'))

class Command
  def initialize()
    @stdout, @stderr, @exit_status = nil
    end
  
  def stdout
    @stdout
  end

  def stderr
    @stderr
  end

  def exit_status
    @exit_status
  end

  def execute(cmdline)
    Open3.popen3(cmdline) do |stdin, stdout, stderr, wait_thr|
      @stdout = stdout.read.chomp
      @stderr = stderr.read.chomp
      @exit_status = wait_thr.value.exitstatus
    end
  end
end

def sudo_exec!(cmd)
  command = Command.new()
  command.execute("sudo #{cmd}")
  return command
end

module ServiceTester
  class InstallException < Exception; end

  class Base
    LOCATION = ENV.fetch('LS_ARTIFACTS_PATH', LS_BUILD_PATH.freeze)
    LOGSTASH_PATH = "/usr/share/logstash/".freeze

    def start_service(service)
      service_manager(service, "start")
    end

    def stop_service(service)
      service_manager(service, "stop")
    end

    def run_command(cmd)
      response = nil
      response = sudo_exec!("JARS_SKIP='true' #{cmd}")
      response
    end

    def replace_in_gemfile(pattern, replace)
      gemfile = File.join(LOGSTASH_PATH, "Gemfile")
      cmd = "sed -i.sedbak 's/#{pattern}/#{replace}/' #{gemfile}"
      run_command(cmd)
    end

    def run_command_in_path(cmd)
      run_command("#{File.join(LOGSTASH_PATH, cmd)}")
    end

    def plugin_installed?(plugin_name, version = nil)
      if version.nil?
        cmd = run_command_in_path("bin/logstash-plugin list")
        search_token = plugin_name
      else
        cmd = run_command_in_path("bin/logstash-plugin list --verbose")
        search_token = "#{plugin_name} (#{version})"
      end

      plugins_list = cmd.stdout.split("\n")
      plugins_list.include?(search_token)
    end

    ##
    # Determines whether a specific gem is included in the vendored distribution.
    #
    # Returns `true` if _any version_ of the gem is vendored.
    #
    # @param gem_name [String]
    # @return [Boolean]
    #   - the block should emit `true` iff the yielded gemspec meets the requirement, and `false` otherwise
    def gem_vendored?(gem_name)
      cmd = run_command("find /usr/share/logstash/vendor/bundle/jruby/*/specifications -name '#{gem_name}-*.gemspec'")
      matches = cmd.stdout.lines
      matches.map do |path_to_gemspec|
        filename = path_to_gemspec.split('/').last
        gemspec_contents = run_command("cat #{path_to_gemspec}").stdout
        Tempfile.create(filename) do |tempfile|
          tempfile.write(gemspec_contents)
          tempfile.flush
          Gem::Specification::load(tempfile.path)
        end
      end.select { |gemspec| gemspec.name == gem_name }.any?
    end

    def download(from, to)
      run_command("curl -fsSL --retry 5 --retry-delay 5 #{from} -o #{to}")
    end

    def write_pipeline(pipeline_string)
      run_command("bash -c \"echo '#{pipeline_string}' >/etc/logstash/conf.d/pipeline.conf\"")
    end

    def delete_file(path)
      run_command("rm -rf #{path}")
    end

    def package_for(filename, skip_jdk_infix, base = ServiceTester::Base::LOCATION)
      jdk_arch_ext = jdk_architecture_extension(skip_jdk_infix)
      File.join(base, "#{filename}#{jdk_arch_ext}.#{package_extension}")
    end

    private
    def jdk_architecture_extension(skip_jdk_infix)
      if skip_jdk_infix
        ""
      else
        "-" + architecture_extension
      end
    end
  end
end
