# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/environment"
require "logstash/config/pipeline_config"

describe ::LogStash::Config::LIRSerializer do
  let(:config) do
    <<-EOC
      input { fake_input {} }
      filter { 
        if ([foo] > 2) {
          fake_filter {} 
        }
      }
      output { fake_output {} }
    EOC
  end
  let(:config_source_with_metadata) do
    [org.logstash.common.SourceWithMetadata.new("string", "spec", config)]
  end

  let(:pipeline_config) { LogStash::Config::PipelineConfig.new("x-pack_lir_serializer_test", "lir", config_source_with_metadata, LogStash::SETTINGS) }

  let(:lir_pipeline) do
    ::LogStash::Compiler.compile_sources(pipeline_config, LogStash::SETTINGS)
  end

  describe "#serialize" do
    it "should serialize cleanly" do
      expect do
        described_class.serialize(lir_pipeline)
      end.not_to raise_error
    end
  end
end
