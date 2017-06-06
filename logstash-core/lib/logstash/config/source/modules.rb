# encoding: utf-8
require "logstash/config/source/base"
require "logstash/config/modules_common"
require "logstash/config/pipeline_config"
require "logstash/util/loggable"
require "logstash/elasticsearch_client"
require "logstash/modules/importer"
require "logstash/errors"

module LogStash module Config module Source
  class Modules < Base
    include LogStash::Util::Loggable
    def pipeline_configs
      pipelines = LogStash::Config::ModulesCommon.pipeline_configs(@settings)
      pipelines.map do |hash|
        PipelineConfig.new(self, hash["pipeline_id"].to_sym,
          org.logstash.common.SourceWithMetadata.new("module", hash["alt_name"], hash["config_string"]),
          hash["settings"])
      end
    end

    def match?
      # will fill this later
      true
    end
  end
end end end
