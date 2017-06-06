# encoding: utf-8
require "logstash/util/loggable"
require "logstash/elasticsearch_client"
require "logstash/modules/importer"
require "logstash/errors"

module LogStash module Config
  class ModulesCommon # extracted here for bwc with 5.x
    include LogStash::Util::Loggable

    def self.pipeline_configs(settings)
      pipelines = []
      plugin_modules = LogStash::PLUGIN_REGISTRY.plugins_with_type(:modules)

      modules_array = settings.get("modules.cli").empty? ? settings.get("modules") : settings.get("modules.cli")
      logger.debug("Configured modules", :modules_array => modules_array.to_s)
      module_names = []
      module_names = modules_array.collect {|module_hash| module_hash["name"]}
      if module_names.length > module_names.uniq.length
        duplicate_modules = module_names.group_by(&:to_s).select { |_,v| v.size > 1 }.keys
        raise LogStash::ConfigLoadingError, I18n.t("logstash.modules.configuration.modules-must-be-unique", :duplicate_modules => duplicate_modules)
      end
      ### Here is where we can force the modules_array to use only [0] for 5.5, and leave
      ### a warning/error message to that effect.
      modules_array.each do |module_hash|
        begin
          import_engine = LogStash::Modules::Importer.new(LogStash::ElasticsearchClient.build(module_hash))

          current_module = plugin_modules.find { |allmodules| allmodules.module_name == module_hash["name"] }
          alt_name = "module-#{module_hash["name"]}"
          pipeline_id = alt_name

          current_module.with_settings(module_hash)
          current_module.import(import_engine)
          config_string = current_module.config_string

          pipelines << {"pipeline_id" => pipeline_id, "alt_name" => alt_name, "config_string" => config_string, "settings" => settings}
        rescue => e
          raise LogStash::ConfigLoadingError, I18n.t("logstash.modules.configuration.parse-failed", :error => e.message)
        end
      end
      pipelines
    end
  end
end end end
