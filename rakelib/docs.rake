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

require "fileutils"

DEFAULT_DOC_DIRECTORY = ::File.join(::File.dirname(__FILE__), "..", "build", "docs")

namespace "docs" do
  desc "Generate documentation for all plugins"
  task "generate" do
    Rake::Task['docs:generate-plugins'].invoke
  end

  desc "Generate the doc for all the currently installed plugins"
  task "generate-plugins", [:output] do |t, args|
    args.with_defaults(:output => DEFAULT_DOC_DIRECTORY)

    require "bootstrap/environment"
    require "logstash-core/logstash-core"
    LogStash::Bundler.setup!({:without => [:build]})

    require "logstash/docgen/logstash_generator"

    FileUtils.mkdir_p(args[:output])
    exit(LogStash::Docgen::LogStashGenerator.new(args[:output]).generate_plugins_docs)
  end
end
