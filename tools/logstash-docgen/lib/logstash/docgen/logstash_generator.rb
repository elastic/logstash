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

require "logstash/docgen/parser"
require "logstash/docgen/index"
require "logstash/docgen/util"
require "logstash/docgen/task_runner"
require "rubygems/specification"
require "fileutils"
require "stud/trap"

module LogStash module Docgen
  # This class is used to generate the documentation inside a working logstash
  # directory, it will take all the installed gemspec and gerate the documentation for them.
  #
  # In practice we will install **all the plugins** before running this generator.
  # This class is invoked inside logstash with a rake task named: `docs:generate-plugins`
  #
  # There is also code to generate `Index` but for now we will still handle them manually.
  class LogStashGenerator
    PLUGIN_RE = /logstash-(codec|input|filter|output)-(\w+)/

    attr_reader :output

    def initialize(output)
      @output = output
      FileUtils.mkdir_p(output)
    end

    def plugins_gemspec
      Gem::Specification.select { |spec| logstash_plugin?(spec.name) }
    end

    def generate(options = {})
      generate_plugins_docs(options)
      generate_index(options)
    end

    def generate_plugins_docs(options = {})
      Util.time_execution do
        task_runner = TaskRunner.new

        # Since this process can be quite long, we allow people to interrupt it,
        # but we should at least dump the currents errors..
        Stud.trap("INT") do
          puts "Process interrupted"
          task_runner.report_failures

          exit(1) # assume something went wrong
        end

        plugins_gemspec.each do |spec|
          task_runner.run(spec.name) do
            generate_plugin_doc(plugin_root(spec), options = {})
          end
        end

        task_runner.report_failures
      end
    end

    def generate_index(options)
      Index.new(output).generate
    end

    def plugin_root(spec)
      spec.load_paths.first.gsub(/lib$/, "")
    end

    def generate_plugin_doc(path, options = {})
      document = Docgen.generate_for_plugin(path, options)
      document.save(output)
    end

    def logstash_plugin?(name)
      name =~ PLUGIN_RE
    end
  end
end end
