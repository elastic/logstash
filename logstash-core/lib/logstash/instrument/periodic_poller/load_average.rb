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

java_import "java.lang.management.ManagementFactory"

module LogStash module Instrument module PeriodicPoller
  class LoadAverage
    class Windows
      def self.get
        nil
      end
    end

    class Linux
      LOAD_AVG_FILE = "/proc/loadavg"
      TOKEN_SEPARATOR = " "

      def self.get(content = ::File.read(LOAD_AVG_FILE))
        load_average = content.chomp.split(TOKEN_SEPARATOR)

        {
          :"1m" => load_average[0].to_f,
          :"5m" => load_average[1].to_f,
          :"15m" => load_average[2].to_f
        }
      end
    end

    class Other
      def self.get()
        load_average_1m = ManagementFactory.getOperatingSystemMXBean().getSystemLoadAverage()

        return nil if load_average_1m.nil?

        {
          :"1m" => load_average_1m
        }
      end
    end

    def self.create
      if LogStash::Environment.windows?
        Windows
      elsif LogStash::Environment.linux?
        Linux
      else
        Other
      end
    end
  end
end end end
