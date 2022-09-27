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

require "logstash/pipeline_action/base"
require "logstash/pipeline_action/create"
require "logstash/pipeline_action/stop"

module LogStash module PipelineAction
  class Reload < Base
    include LogStash::Util::Loggable

    def initialize(pipeline_config, metric)
      @pipeline_config = pipeline_config
      @metric = metric
    end

    def pipeline_id
      @pipeline_config.pipeline_id.to_sym
    end

    def to_s
      "PipelineAction::Reload<#{pipeline_id}>"
    end

    def execute(agent, pipelines_registry)
      old_pipeline = pipelines_registry.get_pipeline(pipeline_id)

      if old_pipeline.nil?
        return LogStash::ConvergeResult::FailedAction.new("Cannot reload pipeline, because the pipeline does not exist")
      end

      if !old_pipeline.reloadable?
        return LogStash::ConvergeResult::FailedAction.new("Cannot reload pipeline, because the existing pipeline is not reloadable")
      end

      begin
        pipeline_validator = LogStash::AbstractPipeline.new(@pipeline_config, nil, logger, nil)
      rescue => e
        return LogStash::ConvergeResult::FailedAction.from_exception(e)
      end

      if !pipeline_validator.reloadable?
        return LogStash::ConvergeResult::FailedAction.new("Cannot reload pipeline, because the new pipeline is not reloadable")
      end

      logger.info("Reloading pipeline", "pipeline.id" => pipeline_id)

      success = pipelines_registry.reload_pipeline(pipeline_id) do
        # important NOT to explicitly return from block here
        # the block must emit a success boolean value

        # First shutdown old pipeline
        old_pipeline.shutdown

        # Then create a new pipeline
        new_pipeline = LogStash::JavaPipeline.new(@pipeline_config, @metric, agent)
        success = new_pipeline.start # block until the pipeline is correctly started or crashed

        # return success and new_pipeline to registry reload_pipeline
        [success, new_pipeline]
      end

      LogStash::ConvergeResult::ActionResult.create(self, success)
    end

  end
end end
