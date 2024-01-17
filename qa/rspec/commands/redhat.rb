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

    def installed?(package)
      stdout = ""
      cmd = sudo_exec!("yum list installed #{package}")
      stdout = cmd.stdout
      stdout.match(/^Installed Packages$/)
      stdout.match(/^logstash.noarch/) || stdout.match(/^logstash.#{architecture_extension}/)
    end

    def package_extension
      "rpm"
    end

    def architecture_extension
      if java.lang.System.getProperty("os.arch") == "amd64"
        "x86_64"
      else
        "aarch64"
      end
    end

    def install(package)
      cmd = sudo_exec!("yum install -y  #{package}")
      if cmd.exit_status != 0
        raise InstallException.new(cmd.stderr.to_s)
      end

    end

    def uninstall(package)
      sudo_exec!("yum remove -y #{package}")
    end

    def removed?(package)
      stdout = ""
      cmd = sudo_exec!("yum list installed #{package}")
      stdout = cmd.stderr
      stdout.match(/^Error: No matching Packages to list$/)
    end
  end
end
