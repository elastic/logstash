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

require 'logstash-core'
require 'logstash/compiler'

module LogStash;
  module Config;
  class LIRSerializer
    attr_reader :lir_pipeline

    def self.serialize(lir_pipeline)
      self.new(lir_pipeline).serialize
    end

    def initialize(lir_pipeline)
      @lir_pipeline = lir_pipeline
    end

    def serialize
      {
        "hash" => lir_pipeline.unique_hash,
        "type" => "lir",
        "version" => "0.0.0",
        "graph" => {
          "vertices" => vertices,
          "edges" => edges
        }
      }
    end

    def vertices
      graph.getVertices.map {|v| vertex(v) }.compact
    end

    def edges
      remove_separators_from_edges(graph.getEdges)
    end

    def graph
      lir_pipeline.graph
    end

    def vertex(v)
      hashified_vertex = case vertex_type(v)
                         when :plugin
                           plugin_vertex(v)
                         when :if
                           if_vertex(v)
                         when :queue
                           queue_vertex(v)
                         when :separator
                           nil
                         end

      decorate_vertex(v, hashified_vertex) unless hashified_vertex.nil?
    end

    def vertex_type(v)
      if v.kind_of?(org.logstash.config.ir.graph.PluginVertex)
        :plugin
      elsif v.kind_of?(org.logstash.config.ir.graph.IfVertex)
        :if
      elsif v.kind_of?(org.logstash.config.ir.graph.QueueVertex)
        :queue
      elsif v.kind_of?(org.logstash.config.ir.graph.SeparatorVertex)
        :separator
      else
        raise "Unexpected vertex type! #{v}"
      end
    end

    def decorate_vertex(v, v_json)
      v_json["meta"] = format_swm(v.source_with_metadata)
      v_json["id"] = v.id
      v_json["explicit_id"] = !!v.explicit_id
      v_json["type"] = vertex_type(v).to_s
      v_json
    end

    def plugin_vertex(v)
      pd = v.plugin_definition
      {
        "config_name" => pd.name,
        "plugin_type" => pd.getType.to_s.downcase
      }
    end

    def if_vertex(v)
      {
        "condition" => v.humanReadableExpression
      }
    end

    def queue_vertex(v)
      {}
    end

    def separator_vertex(v)
      {}
    end

    # For separators, create new edges going between the incoming and all of the outgoing edges, and remove
    # the separator vertices from the serialized output.
    def remove_separators_from_edges(edges)
      edges_with_separators_removed = []
      edges.each do |e|
        if vertex_type(e.to) == :separator
          e.to.getOutgoingEdges.each do |outgoing|
            if e.kind_of?(org.logstash.config.ir.graph.BooleanEdge)
              edges_with_separators_removed << edge(org.logstash.config.ir.graph.BooleanEdge.new(e.edgeType, e.from, outgoing.to))
            else
              edges_with_separators_removed << edge(org.logstash.config.ir.graph.PlainEdge.factory.make(e.from, outgoing.to))
            end
          end
        elsif vertex_type(e.from) == :separator
          # Skip the edges coming from the 'from' separator
        else
          edges_with_separators_removed << edge(e)
        end
      end
      edges_with_separators_removed
    end

    def edge(e)
      e_json = {
        "from" => e.from.id,
        "to" => e.to.id,
        "id" => e.id
      }

      if e.kind_of?(org.logstash.config.ir.graph.BooleanEdge)
        e_json["when"] = e.edge_type
        e_json["type"] = "boolean"
      else
        e_json["type"] = "plain"
      end

      e_json
    end

    def format_swm(source_with_metadata)
      return nil unless source_with_metadata
      {
        "source" => {
          "protocol" => source_with_metadata.protocol,
          "id" => source_with_metadata.id,
          "line" =>  source_with_metadata.line,
          "column" => source_with_metadata.column
          # We omit the text of the source code for security reasons
          # raw text may contain passwords
        }
      }
    end

  end
  end
end
