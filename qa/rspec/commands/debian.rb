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
  class DebianCommands < Base

    include ::ServiceTester::SystemD

    def installed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("dpkg -s  #{package}")
        stdout = cmd.stdout
      end
      stdout.match(/^Package: #{package}$/)
      stdout.match(/^Status: install ok installed$/)
    end

    def package_extension
      "deb"
    end

    def architecture_extension
      "amd64"
    end

    def install(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      errors = []
      at(hosts, {in: :serial}) do |_|
        cmd = sudo_exec!("dpkg -i --force-confnew #{package}")
        if cmd.exit_status != 0
          errors << cmd.stderr.to_s
        end
      end
      raise InstallException.new(errors.join("\n")) unless errors.empty?
    end

    def uninstall(package, host=nil)
      hosts = (host.nil? ? servers : Array(host))
      at(hosts, {in: :serial}) do |_|
        sudo_exec!("dpkg -r #{package}")
        sudo_exec!("dpkg --purge #{package}")
      end
    end

    def removed?(hosts, package)
      stdout = ""
      at(hosts, {in: :serial}) do |host|
        cmd = sudo_exec!("dpkg -s #{package}")
        stdout = cmd.stderr
      end
      (
        stdout.match(/^Package `#{package}' is not installed and no info is available.$/) ||
        stdout.match(/^dpkg-query: package '#{package}' is not installed and no information is available$/)
      )
    end
  end
end
