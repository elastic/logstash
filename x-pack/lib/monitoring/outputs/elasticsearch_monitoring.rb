# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

module LogStash module Outputs
  class ElasticSearchMonitoring < LogStash::Outputs::ElasticSearch
    config_name "elasticsearch_monitoring"

    # This is need to avoid deprecation warning in output
    config :document_type, :validate => :string

    def use_event_type?(client)
      !LogStash::MonitoringExtension.use_direct_shipping?(LogStash::SETTINGS)
    end
  end
end; end
