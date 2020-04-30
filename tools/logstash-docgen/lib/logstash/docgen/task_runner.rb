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

require "logstash/docgen/util"

module LogStash module Docgen
  class TaskRunner
    TERMINAL_MAX_WIDTH = 80

    class Status
      attr_reader :name, :error

      def initialize(name, error = nil)
        @name = name
        @error = error
      end

      def success?
        error.nil?
      end
    end

    def initialize
      @delayed_failures = []
    end

    def run(job_name, &block)
      begin
        block.call
        report(Status.new(job_name))
      rescue => e
        report(Status.new(job_name, e))
      end
    end

    def report_failures
      if failures?
        puts "-" * TERMINAL_MAX_WIDTH

        @delayed_failures.each do |failure|
          puts Util.red("FAILURE: #{failure.name}")
          puts Util.red("\tException: #{failure.error.class} message: #{failure.error}")
          puts "\t\t#{Util.red(failure.error.backtrace.join("\n\t\t"))}"
          puts "\n"
        end
        return true
      else
        return false
      end
    end

    def failures?
      @delayed_failures.size > 0
    end

    def report(status)
      if status.success?
        puts "#{status.name} > #{Util.green("SUCCESS")}"
      else
        puts "#{status.name} > #{Util.red("FAIL")}"
        @delayed_failures << status
      end
    end
  end
end end
