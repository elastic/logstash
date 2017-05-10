# encoding: utf-8
require "logstash/errors"

module LogStash module BootstrapCheck
  class DefaultConfig
    def self.check(settings)

      if settings.get("config.string") && settings.get("path.config")
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.config-string-path-exclusive")
      end

      # Check for attempted usage of both modules (in either the YAML file or the command line)
      # in conjunction with either -e or -f and disallow (for now?)
      if (settings.get("config.string") || settings.get("path.config")) && (settings.get("modules.cli") != [] || settings.get("modules") != [])
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.config-module-exclusive")
      # Check for the absence of any (modules in YAML or cmdline, or -e or -f) 
      elsif (settings.get("modules.cli") == [] && settings.get("modules") == []) && (settings.get("config.string").nil? && settings.get("path.config").nil?)
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.missing-configuration")
      end

      if settings.get("config.reload.automatic") && settings.get("path.config").nil?
        # there's nothing to reload
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.reload-without-config-path")
      end
    end
  end
end end
