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

require 'rubygems'

::Gem.clear_paths

ENV['GEM_HOME'] = ENV['GEM_PATH'] = ::File.expand_path(
    ::File.join(__FILE__, "..", "..", "..", "build", "qa", "integration", "vendor", "jruby", "3.1.0")
)

::Gem.paths = ENV

require "bundler"
::Bundler.setup

require "rspec"
require "rspec/core"

RSpec.clear_examples

RSpec.configure do |c|
  timer = Class.new do
    def initialize
      @timings = Hash.new(0)
      @mutex = Mutex.new
    end

    def record(example)
      start_time = now_millis
      example.run
    ensure
      duration_millis = (now_millis - start_time)
      spec_path = Pathname.new(example.file_path).cleanpath.to_s
      @mutex.synchronize { @timings[spec_path] += duration_millis }
    end

    def write
      @mutex.synchronize do
        @timings.sort.each do |filename, time_millis|
          $stderr.puts("[TIME #{filename}](#{(time_millis/1000.0).ceil})")
        end
      end
    end

    private

    ##
    # Get the current time in millis directly from Java,
    # bypassing any ruby time-mocking libs
    # @return [Integer]
    def now_millis
      java.lang.System.currentTimeMillis()
    end
  end.new

  c.around(:example) { |example| timer.record(example) }
  c.after(:suite) { timer.write }
end

RSpec.configure do |c|
  c.filter_run_excluding skip_fips: true if java.lang.System.getProperty("org.bouncycastle.fips.approved_only") == "true"
end

return RSpec::Core::Runner.run($JUNIT_ARGV).to_i
