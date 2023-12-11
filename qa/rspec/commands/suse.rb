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
  class SuseCommands < Base

    def installed?(package)
      stdout = ""
      cmd = sudo_exec!("zypper search #{package}")
      stdout = cmd.stdout
      stdout.match(/^i | logstash | An extensible logging pipeline | package$/)
    end

    def package_extension()
      "rpm"
    end

    def architecture_extension()
      "x86_64"
    end

    def install(package)
      cmd = sudo_exec!("zypper --no-gpg-checks --non-interactive install  #{package}")
      if cmd.exit_status != 0
        raise InstallException.new(cmd.stderr.to_s)
      end
    end

    def uninstall(package)
      cmd = sudo_exec!("zypper --no-gpg-checks --non-interactive remove #{package}")
    end

    def removed?(package)
      stdout = ""
      cmd    = sudo_exec!("zypper search #{package}")
      stdout = cmd.stdout
      stdout.match(/No packages found/)
    end

    def running?(package)
      stdout = ""
      cmd = sudo_exec!("service #{package} status")
      stdout = cmd.stdout
      stdout.match(/Active: active \(running\)/)
    end

    def service_manager(service, action)
      sudo_exec!("service #{service} #{action}")
    end
  end
end
