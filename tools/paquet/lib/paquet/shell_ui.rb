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

module Paquet
  class SilentUI
    class << self
      def debug(message)
      end

      def info(message)
      end
    end
  end

  class ShellUi
    def debug(message)
      report_message(:debug, message) if debug?
    end

    def info(message)
      report_message(:info, message)
    end

    def report_message(level, message)
      puts "[#{level.upcase}]: #{message}"
    end

    def debug?
      ENV["DEBUG"]
    end
  end

  def self.ui
    @logger ||= ShellUi.new
  end

  def self.ui=(new_output)
    @logger = new_output
  end
end
