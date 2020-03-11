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

require 'logstash/compiler/lscl/lscl_grammar'

java_import org.logstash.config.ir.PipelineIR
java_import org.logstash.config.ir.graph.Graph

module LogStash; class Compiler
  include ::LogStash::Util::Loggable

  def self.compile_sources(sources_with_metadata, support_escapes)
    graph_sections = sources_with_metadata.map do |swm|
      self.compile_graph(swm, support_escapes)
    end

    input_graph = Graph.combine(*graph_sections.map {|s| s[:input] }).graph
    output_graph = Graph.combine(*graph_sections.map {|s| s[:output] }).graph

    filter_graph = graph_sections.reduce(nil) do |acc, s|
      filter_section = s[:filter]

      if acc.nil?
        filter_section
      else
        acc.chain(filter_section)
      end
    end

    original_source = sources_with_metadata.map(&:text).join("\n")

    PipelineIR.new(input_graph, filter_graph, output_graph, original_source)
  end

  def self.compile_imperative(source_with_metadata, support_escapes)
    if !source_with_metadata.is_a?(org.logstash.common.SourceWithMetadata)
      raise ArgumentError, "Expected 'org.logstash.common.SourceWithMetadata', got #{source_with_metadata.class}"
    end

    grammar = LogStashCompilerLSCLGrammarParser.new
    config = grammar.parse(source_with_metadata.text)

    if config.nil?
      raise ConfigurationError, grammar.failure_reason
    end

    config.process_escape_sequences = support_escapes
    config.compile(source_with_metadata)
  end

  def self.compile_graph(source_with_metadata, support_escapes)
    Hash[compile_imperative(source_with_metadata, support_escapes).map {|section,icompiled| [section, icompiled.toGraph]}]
  end
end; end
