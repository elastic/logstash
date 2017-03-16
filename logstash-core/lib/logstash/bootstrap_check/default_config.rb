# encoding: utf-8
require "logstash/errors"

module LogStash module BootstrapCheck
  class DefaultConfig
    def self.check(settings)
      # currently none of the checks applies if there are multiple pipelines
      if settings.get("config.reload.automatic") && settings.get_setting("config.string").set?
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.reload-with-config-string")
      end
    end
  end
end end
