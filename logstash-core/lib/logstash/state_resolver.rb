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

module LogStash
  # In the beginning I was using this code as a method in the Agent class directly
  # But with the plugins system I think we should be able to swap what kind of action would be run.
  #
  # Lets take the example of dynamic source, where the pipeline config and settings are located and
  # managed outside of the machine.
  class StateResolver
    def initialize(metric)
      @metric = metric
    end

    def resolve(pipelines_registry, pipeline_configs)
      actions = []

      pipeline_configs.each do |pipeline_config|
        pipeline = pipelines_registry.get_pipeline(pipeline_config.pipeline_id)

        if pipeline.nil?
          actions << LogStash::PipelineAction::Create.new(pipeline_config, @metric)
        else
          if pipeline_config != pipeline.pipeline_config
            actions << LogStash::PipelineAction::Reload.new(pipeline_config, @metric)
          end
        end
      end

      configured_pipelines = pipeline_configs.each_with_object(Set.new) { |config, set| set.add(config.pipeline_id.to_sym) }

      # If one of the running pipeline is not in the pipeline_configs, we assume that we need to
      # stop it and delete it in registry.
      pipelines_registry.running_pipelines(include_loading: true).keys
        .select { |pipeline_id| !configured_pipelines.include?(pipeline_id) }
        .each { |pipeline_id| actions << LogStash::PipelineAction::StopAndDelete.new(pipeline_id) }

      # If one of the terminated pipeline is not in the pipeline_configs, delete it in registry.
      pipelines_registry.non_running_pipelines.keys
        .select { |pipeline_id| !configured_pipelines.include?(pipeline_id) }
        .each { |pipeline_id| actions << LogStash::PipelineAction::Delete.new(pipeline_id)}

      actions.sort # See logstash/pipeline_action.rb
    end
  end
end
