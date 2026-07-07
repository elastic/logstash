# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "security/fips_bootstrap_check"

module LogStash
  module Security
    class Extension < LogStash::UniversalPlugin
      include LogStash::Util::Loggable

      def register_hooks(hooks)
        require "logstash/runner"
        hooks.register_hooks(LogStash::Runner, Hooks.new)
      end

      def additionals_settings(settings)
        logger.trace("Registering security settings")
        settings.register(LogStash::Setting::BooleanSetting.new("xpack.security.fips_mode.enabled", false))
        settings.register(LogStash::Setting::StringArray.new("xpack.security.fips_mode.required_providers", []))
      rescue => e
        logger.error("Cannot register security settings", :message => e.message, :backtrace => e.backtrace)
        raise e
      end
    end

    class Hooks
      def before_bootstrap_checks(runner)
        runner.bootstrap_checks << FipsBootstrapCheck
      end
    end
  end
end
