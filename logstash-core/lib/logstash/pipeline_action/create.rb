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
  class Create < Base
    include LogStash::Util::Loggable

    # We currently pass around the metric object again this
    # is needed to correctly create a pipeline, in a future
    # PR we could pass a factory to create the pipeline so we pass the logic
    # to create the pipeline instead.
    def initialize(pipeline_config, metric)
      @pipeline_config = pipeline_config
      @metric = metric
    end

    def pipeline_id
      @pipeline_config.pipeline_id.to_sym
    end

    # Make sure we execution system pipeline like the monitoring
    # before any user defined pipelines, system pipeline register hooks into the system that will be
    # triggered by the user defined pipeline.
    def execution_priority
      default_priority = super
      @pipeline_config.system? ? default_priority * -1 : default_priority
    end

    # The execute assume that the thread safety access of the pipeline
    # is managed by the caller.
    def execute(agent, pipelines_registry)
      new_pipeline = LogStash::JavaPipeline.new(@pipeline_config, @metric, agent)
      success = pipelines_registry.create_pipeline(pipeline_id, new_pipeline) do
        new_pipeline.start # block until the pipeline is correctly started or crashed
      end
      LogStash::ConvergeResult::ActionResult.create(self, success)
    end

    def to_s
      "PipelineAction::Create<#{pipeline_id}>"
    end
  end
end end
