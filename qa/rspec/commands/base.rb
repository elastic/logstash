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

require_relative "../../vagrant/helpers"
require_relative "system_helpers"

module ServiceTester

  class InstallException < Exception; end

  class Base
    LOCATION="/logstash-build".freeze
    LOGSTASH_PATH="/usr/share/logstash/".freeze

    def snapshot(host)
      LogStash::VagrantHelpers.save_snapshot(host)
    end

    def restore(host)
      LogStash::VagrantHelpers.restore_snapshot(host)
    end

    def start_service(service, host=nil)
      service_manager(service, "start", host)
    end

    def stop_service(service, host=nil)
      service_manager(service, "stop", host)
    end

    def run_command(cmd, host)
      hosts = (host.nil? ? servers : Array(host))

      response = nil
      at(hosts, {in: :serial}) do |_host|
        response = sudo_exec!("JARS_SKIP='true' #{cmd}")
      end
      response
    end

    def replace_in_gemfile(pattern, replace, host)
      gemfile = File.join(LOGSTASH_PATH, "Gemfile")
      cmd = "sed -i.sedbak 's/#{pattern}/#{replace}/' #{gemfile}"
      run_command(cmd, host)
    end

    def run_command_in_path(cmd, host)
      run_command("#{File.join(LOGSTASH_PATH, cmd)}", host)
    end

    def plugin_installed?(host, plugin_name, version = nil)
      if version.nil?
        cmd = run_command_in_path("bin/logstash-plugin list", host)
        search_token = plugin_name
      else
        cmd = run_command_in_path("bin/logstash-plugin list --verbose", host)
        search_token ="#{plugin_name} (#{version})"
      end

      plugins_list = cmd.stdout.split("\n")
      plugins_list.include?(search_token)
    end

    def download(from, to, host)
      run_command("wget #{from} -O #{to}", host)
    end

    def delete_file(path, host)
      run_command("rm -rf #{path}", host)
    end

    def package_for(filename, skip_jdk_infix, bundled_jdk, base=ServiceTester::Base::LOCATION)
      jdk_arch_ext = jdk_architecture_extension(skip_jdk_infix, bundled_jdk)
      File.join(base, "#{filename}#{jdk_arch_ext}.#{package_extension}")
    end

    private
    def jdk_architecture_extension(skip_jdk_infix, bundled_jdk)
      if skip_jdk_infix
        ""
      else
        if bundled_jdk
          "-" + architecture_extension
        else
          "-no-jdk"
        end
      end
    end
  end
end
