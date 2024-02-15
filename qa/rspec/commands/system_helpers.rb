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
  module SystemD
    def running?(package, jdk_path = '/usr/share/logstash/jdk/bin/java')
      stdout = ""
      cmd = sudo_exec!("service #{package} status")
      stdout = cmd.stdout
      stdout.force_encoding(Encoding::UTF_8)
      (
        stdout.match(/Active: active \(running\)/) &&
        stdout.match(/^\s*(└─|`-)\d*\s.*#{jdk_path}.*org\.logstash\.Logstash/) &&
        stdout.match(/#{package}.service - #{package}/)
      )
    end

    def service_manager(service, action)
      sudo_exec!("service #{service} #{action}")
    end
  end

  module InitD
    def running?(package, jdk_path = '/usr/share/logstash/jdk/bin/java')
      stdout = ""
      cmd = sudo_exec!("initctl status #{package}")
      stdout = cmd.stdout
      running = stdout.match(/#{package} start\/running/)
      if running
        pid = stdout.match(/#{package} start\/running, process (\d*)/).captures[0]
        cmd = sudo_exec!("ps ax | grep #{pid}")
        stdout = cmd.stdout
        running = (running && stdout.match(/#{jdk_path}/))
      end
      running
    end

    def service_manager(service, action)
      sudo_exec!("initctl #{action} #{service}")
    end
  end
end
