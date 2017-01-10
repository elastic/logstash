# encoding: utf-8
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

    def resolve(pipelines, pipeline_configs)
      actions = []

      pipeline_configs.each do |pipeline_config|
        pipeline = pipelines[pipeline_config.pipeline_id]

        if pipeline.nil?
          actions << LogStash::PipelineAction::Create.new(pipeline_config, @metric)
        else
          # TODO(ph): The pipeline should keep a reference to the original PipelineConfig
          # and we could use straight comparison.
          if pipeline_config.config_hash != pipeline.config_hash
            actions << LogStash::PipelineAction::Reload.new(pipeline_config, @metric)
          end
        end
      end

      running_pipelines = pipeline_configs.collect(&:pipeline_id)

      # If one of the running pipeline is not in the pipeline_configs, we assume that we need to
      # stop it.
      pipelines.keys
        .select { |pipeline_id| !running_pipelines.include?(pipeline_id) }
        .each { |pipeline_id| actions << LogStash::PipelineAction::Stop.new(pipeline_id) }

      actions.sort # See logstash/pipeline_action.rb
    end
  end
end
