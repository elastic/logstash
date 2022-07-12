# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash; module Inputs; class Metrics;
  class StateEventFactory
    require "logstash/config/lir_serializer"

    def initialize(pipeline, cluster_uuid, collection_interval = 10)
      raise ArgumentError, "No pipeline passed in!" unless pipeline.is_a?(LogStash::JavaPipeline)

      pipeline_doc = {"pipeline" => pipeline_data(pipeline)}

      if (LogStash::MonitoringExtension.use_direct_shipping?(LogStash::SETTINGS))
        event_body = {
          "type" => "logstash_state",
          "logstash_state" => pipeline_doc,
          "cluster_uuid" => cluster_uuid,
          "interval_ms" => collection_interval * 1000,
          "timestamp" => DateTime.now.strftime('%Y-%m-%dT%H:%M:%S.%L%z')
        }
      else
        event_body = pipeline_doc
      end

      @event = LogStash::Event.new(
        {"@metadata" => {
          "document_type" => "logstash_state",
          "timestamp" => Time.now
        }}.merge(event_body)
      )

      @event.remove("@timestamp")
      @event.remove("@version")

      @event
    end

    def pipeline_data(pipeline)
      {
        "id" => pipeline.pipeline_id,
        "hash" => pipeline.lir.unique_hash,
        "ephemeral_id" => pipeline.ephemeral_id,
        "workers" =>  pipeline.settings.get("pipeline.workers"),
        "batch_size" =>  pipeline.settings.get("pipeline.batch.size"),
        "representation" => ::LogStash::Config::LIRSerializer.serialize(pipeline.lir)
      }
    end

    def make
      @event
    end
  end
end; end; end
