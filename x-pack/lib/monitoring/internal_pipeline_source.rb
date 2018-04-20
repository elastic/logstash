# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/config/source/base"

module LogStash module Monitoring
  class InternalPipelineSource < LogStash::Config::Source::Base
    def initialize(pipeline_config)
      super(pipeline_config.settings)
      @pipeline_config = pipeline_config
    end

    def pipeline_configs
      return @pipeline_config
    end

    def match?
      true
    end
  end
end end
