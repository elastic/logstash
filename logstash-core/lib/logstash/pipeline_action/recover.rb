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
require "logstash/java_pipeline"

module LogStash module PipelineAction
  class Recover < Base
    include LogStash::Util::Loggable

    def initialize(pipeline_config, metric)
      @pipeline_config = pipeline_config
      @metric = metric
    end

    def pipeline_id
      @pipeline_config.pipeline_id.to_sym
    end

    def to_s
      "PipelineAction::Recover<#{pipeline_id}>"
    end

    def execute(agent, pipelines_registry)
      old_pipeline = pipelines_registry.get_pipeline(pipeline_id)

      # guard with descriptive errors
      if old_pipeline.nil?
        return new_failed_action("pipeline does not exist")
      elsif old_pipeline.running? || !old_pipeline.crashed?
        return new_failed_action("existing pipeline is not in a settled crashed state")
      elsif !old_pipeline.configured_as_recoverable?
        return new_failed_action("existing pipeline not configured to be recoverable (see: `pipeline.recoverable`)")
      elsif (nrp = old_pipeline.non_reloadable_plugins) && !nrp.empty?
        return new_failed_action("existing pipeline has non-reloadable plugins: #{nrp.map(&:readable_spec).join(', ')}")
      end

      begin
        pipeline_validator = AbstractPipeline.new(@pipeline_config, nil, logger, nil)
      rescue => e
        return ConvergeResult::FailedAction.from_exception(e)
      end

      if !pipeline_validator.reloadable?
        return new_failed_action("Cannot recover pipeline, because the new pipeline is not reloadable")
      end

      logger.info("Recovering pipeline", "pipeline.id" => pipeline_id)

      success = pipelines_registry.reload_pipeline(pipeline_id) do
        # important NOT to explicitly return from block here
        # the block must emit a success boolean value

        # first cleanup the old pipeline
        old_pipeline.shutdown

        # Then create a new pipeline
        new_pipeline = LogStash::JavaPipeline.new(@pipeline_config, @metric, agent)
        success = new_pipeline.start # block until the pipeline is correctly started or crashed

        # return success and new_pipeline to registry reload_pipeline
        [success, new_pipeline]
      end
      pipelines_registry.states.get(pipeline_id)&.mark_recovery if success

      LogStash::ConvergeResult::ActionResult.create(self, success)
    end

  end
end; end