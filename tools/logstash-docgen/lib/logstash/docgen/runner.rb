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

require "logstash/docgen/github_generator"
require "clamp"
require "yaml"

module LogStash module Docgen
  class Runner < Clamp::Command
    SAMPLE_PLUGINS = %w(logstash-input-http_poller logstash-codec-netflow logstash-codec-multiline logstash-mixin-aws)

    option ["-t", "--target"], "target", "Where the generated documentation should be saved?", :default => File.join(Dir.pwd, "target")
    option ["-a", "--all"], :flag, "generate the doc for all the plugins"
    option ["-s", "--sample"], :flag, "Use a few plugins to test, logstash-input-sqs, logstash-input-file"
    option ["-c", "--config"], "config", "Configuration of documentation generator", :default => File.join(Dir.pwd, "logstash-docgen.yml")
    option ["-i", "--source"], "source", "Where we checkout the plugins, having the same source can make runs faster", :default => File.join(Dir.pwd, "source")

    parameter "[PLUGIN] ...", "Specific plugin", :attribute_name => :plugins

    def execute
      if plugins.size > 0
        with_plugins = plugins
      elsif sample?
        with_plugins = SAMPLE_PLUGINS
      else
        with_plugins = :all
      end

      DocumentationGenerator.new(with_plugins,
                                 target,
                                 source,
                                 YAML.load(File.read(config))).generate
    end
  end
end end
