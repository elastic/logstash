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

require_relative "base"

module ServiceTester
  class RedhatCommands < Base

    include ::ServiceTester::SystemD

    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = exec!("yum list installed  #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^Installed Packages$/)
      stdout.match(/^logstash.noarch/)
    end

    def package_extension
      "rpm"
    end

    def architecture_extension
      "x86_64"
    end

    def install(package, host=nil)
      hosts  = (host.nil? ? servers : Array(host))
      errors = []
      exit_status = 0
      at(hosts, {in: :serial}) do |_host|
        cmd = sudo_exec!("yum install -y  #{package}")
        exit_status += cmd.exit_status
        errors << cmd.stderr unless cmd.stderr.empty?
      end
      if exit_status > 0 
        raise InstallException.new(errors.join("\n"))
      end
    end

    def uninstall(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("yum remove -y #{package}")
      end
    end

    def removed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("yum list installed #{package}")
        stdout = cmd.stderr
      end
      stdout.match(/^Error: No matching Packages to list$/)
    end
  end
end
