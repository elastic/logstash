# encoding: utf-8
require "logstash/errors"
require "logstash/logging"

module LogStash module BootstrapCheck
  class DefaultConfig
    include LogStash::Util::Loggable

    def initialize(settings)
      @settings = settings
    end

    def config_reload?
      @settings.get("config.reload.automatic")
    end

    def config_string?
      @settings.get("config.string")
    end

    def path_config?
      @settings.get("path.config")
    end

    def config_modules?
      # We want it to report true if not empty
      !@settings.get("modules").empty?
    end

    def cli_modules?
      # We want it to report true if not empty
      !@settings.get("modules.cli").empty?
    end

    def both_config_flags?
      config_string? && path_config?
    end

    def both_module_configs?
      cli_modules? && config_modules?
    end

    def config_defined?
      config_string? || path_config?
    end

    def modules_defined?
      cli_modules? || config_modules?
    end

    def any_config?
      config_defined? || modules_defined?
    end

    def check
      # Check if both -f and -e are present
      if both_config_flags?
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.config-string-path-exclusive")
      end

      # Make note that if modules are configured in both cli and logstash.yml that cli module  
      # settings will be used, and logstash.yml modules settings ignored
      if both_module_configs?
        logger.info(I18n.t("logstash.runner.cli-module-override"))
      end

      # Check if both config (-f or -e) and modules are configured
      if config_defined? && modules_defined?
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.config-module-exclusive")
      end

      # Check for absence of any configuration
      if !any_config?
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.missing-configuration")
      end

      # Check to ensure that if configuration auto-reload is used that -f is specified
      if config_reload? && !path_config?
        raise LogStash::BootstrapCheckError, I18n.t("logstash.runner.reload-without-config-path")
      end
    end

    def self.check(settings)
      DefaultConfig.new(settings).check
    end
  end
end end
