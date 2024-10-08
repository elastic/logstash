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

module LogStash module PipelineAction
  class Delete < Base
    attr_reader :pipeline_id

    def initialize(pipeline_id)
      @pipeline_id = pipeline_id
    end

    def execute(agent, pipelines_registry)
      success = pipelines_registry.delete_pipeline(@pipeline_id)
      detach_health_indicator(agent) if success

      LogStash::ConvergeResult::ActionResult.create(self, success)
    end

    def detach_health_indicator(agent)
      agent.health_observer.detach_pipeline_indicator(pipeline_id)
    end

    def to_s
      "PipelineAction::Delete<#{pipeline_id}>"
    end
  end
end end
