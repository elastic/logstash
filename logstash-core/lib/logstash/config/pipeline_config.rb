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

require "digest"

module LogStash module Config
  class PipelineConfig
    include LogStash::Util::Loggable

    LineToSource = Struct.new("LineToSource", :bounds, :source)

    attr_reader :source, :pipeline_id, :config_parts, :settings, :read_at

    def initialize(source, pipeline_id, config_parts, settings)
      @source = source
      @pipeline_id = pipeline_id
      # We can't use Array() since config_parts may be a java object!
      config_parts_array = config_parts.is_a?(Array) ? config_parts : [config_parts]
      @config_parts = config_parts_array.sort_by { |config_part| [config_part.protocol.to_s, config_part.id] }
      @settings = settings
      @read_at = Time.now
    end

    def config_hash
      @config_hash ||= Digest::SHA1.hexdigest(config_string)
    end

    def config_string
      @config_string = config_parts.collect(&:text).join("\n")
    end

    def system?
      @settings.get("pipeline.system")
    end

    def ==(other)
      config_hash == other.config_hash && pipeline_id == other.pipeline_id && settings == other.settings
    end

    def display_debug_information
      logger.debug("-------- Logstash Config ---------")
      logger.debug("Config from source", :source => source, :pipeline_id => pipeline_id)

      config_parts.each do |config_part|
        logger.debug("Config string", :protocol => config_part.protocol, :id => config_part.id)
        logger.debug("\n\n#{config_part.text}")
      end
      logger.debug("Merged config")
      logger.debug("\n\n#{config_string}")
    end

    def lookup_source(global_line_number, source_column)
      res = source_references.find { |line_to_source| line_to_source.bounds.include? global_line_number }
      if res == nil
        raise IndexError, "can't find the config segment related to line #{global_line_number}"
      end
      swm = res.source
      SourceWithMetadata.new(swm.getProtocol(), swm.getId(), global_line_number + 1 - res.bounds.begin, source_column, swm.getText())
    end

    private
    def source_references
      @source_refs ||= begin
        offset = 0
        source_refs = []
        config_parts.each do |config_part|
          #line numbers starts from 1 in text files
          lines_range = (config_part.getLine() + offset + 1..config_part.getLinesCount() + offset)
          source_segment = LineToSource.new(lines_range, config_part)
          source_refs << source_segment
          offset += config_part.getLinesCount()
        end
        source_refs.freeze
      end
    end
  end
end end
