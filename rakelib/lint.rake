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

namespace "lint" do
  module RuboCLI
    def self.run!(*args)
      require "rubocop"
      cli = RuboCop::CLI.new
      result = cli.run(["--force-exclusion", *args])
      raise "Linting failed." if result.nonzero?
    end
  end

  # task that runs lint report
  desc "Report all Lint Cops"
  task "report" do
    RuboCLI.run!("--lint")
  end

  # Tasks automatically fixes a Cop passed as a parameter (e.g. Lint/DeprecatedClassMethods)
  # TODO: Add a way to autocorrect all cops, and not just the one passed as parameter
  desc "Automatically fix all instances of a Cop passed as a parameter"
  task "correct", [:cop] do |t, args|
    if args[:cop].to_s.empty?
      puts "No Cop has been provided, aborting..."
      exit(0)
    else
      puts "Attempting to correct Lint issues for: #{args[:cop].to_s}"
      RuboCLI.run!("--autocorrect-all", "--only", args[:cop].to_s)
    end
  end

  # task that automatically fixes code formatting
  desc "Automatically fix Layout Cops"
  task "format" do
    RuboCLI.run!("--fix-layout")
  end
end
