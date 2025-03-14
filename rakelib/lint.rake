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

  desc "Report all Lint Cops. Optional: Specify one or more files"
  task :report, [:file] do |t, args|
    files = [args[:file], *args.extras].compact

    if files.empty?
      RuboCLI.run!("--lint")
    else
      puts "Running lint report on specific files: #{files.join(', ')}"
      RuboCLI.run!("--lint", *files)
    end
  end

  # Tasks automatically fixes a Cop passed as a parameter
  desc "Automatically fix all instances of a Cop passed as a parameter. Optional: Specify one or more files"
  task :correct, [:cop] do |t, args|
    if args[:cop].to_s.empty?
      puts "No Cop has been provided, aborting..."
      exit(0)
    else
      files = args.extras
      if files.empty?
        puts "Attempting to correct Lint issues for: #{args[:cop]}"
        RuboCLI.run!("--autocorrect-all", "--only", args[:cop])
      else
        puts "Attempting to correct Lint issues for #{args[:cop]} in files: #{files.join(', ')}"
        RuboCLI.run!("--autocorrect-all", "--only", args[:cop], *files)
      end
    end
  end

  desc "Automatically fix Layout Cops. Optional: Specify one or more files"
  task :format, [:file] do |t, args|
    files = [args[:file], *args.extras].compact
    if files.empty?
      RuboCLI.run!("--fix-layout")
    else
      puts "Running format fixes on specific files: #{files.join(', ')}"
      RuboCLI.run!("--fix-layout", *files)
    end
  end
end