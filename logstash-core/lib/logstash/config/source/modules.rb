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

require "logstash/config/source/base"
require "logstash/config/modules_common"

module LogStash module Config module Source
  class Modules < Base
    include LogStash::Util::Loggable
    def pipeline_configs
      if config_conflict? # double check
        raise ConfigurationError, @conflict_messages.join(", ")
      end

      pipelines = LogStash::Config::ModulesCommon.pipeline_configs(@settings)
      pipelines.map do |hash|
        org.logstash.config.ir.PipelineConfig.new(self.class, hash["pipeline_id"].to_sym,
          org.logstash.common.SourceWithMetadata.new("module", hash["alt_name"], 0, 0, hash["config_string"]),
          hash["settings"])
      end
    end

    def match?
      # see basic settings predicates and getters defined in the base class
      (modules_cli? || modules?) && !(config_string? || config_path?) && !automatic_reload_with_modules?
    end

    def config_conflict?
      @conflict_messages.clear
      # Make note that if modules are configured in both cli and logstash.yml that cli module
      # settings will overwrite the logstash.yml modules settings
      if modules_cli? && modules?
        logger.info(I18n.t("logstash.runner.cli-module-override"))
      end

      if automatic_reload_with_modules?
        @conflict_messages << I18n.t("logstash.runner.reload-with-modules")
      end

      # Check if config (-f or -e) and modules are configured
      if (modules_cli? || modules?) && (config_string? || config_path?)
        @conflict_messages << I18n.t("logstash.runner.config-module-exclusive")
      end

      @conflict_messages.any?
    end

    private

    def automatic_reload_with_modules?
      (modules_cli? || modules?) && config_reload_automatic?
    end
  end
end end end
