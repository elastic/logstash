# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/environment"

module LogStash module GeoipDatabaseManagement
  class Extension < LogStash::UniversalPlugin
    include LogStash::Util::Loggable

    def additionals_settings(settings)
      require "logstash/runner"
      logger.trace("Registering additional geoip settings")
      settings.register(LogStash::Setting::String.new("xpack.geoip.downloader.endpoint", "https://geoip.elastic.co/v1/database")
                                                 .with_deprecated_alias("xpack.geoip.download.endpoint"))
      settings.register(LogStash::Setting::TimeValue.new("xpack.geoip.downloader.poll.interval", "24h"))
      settings.register(LogStash::Setting::Boolean.new("xpack.geoip.downloader.enabled", true))
    rescue => e
      logger.error("Cannot register new settings", :message => e.message, :backtrace => e.backtrace)
      raise e
    end
  end
end end