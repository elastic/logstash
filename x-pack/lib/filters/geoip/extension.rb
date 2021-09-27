# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/environment"

module LogStash module Filters module Geoip
  class Extension < LogStash::UniversalPlugin
    include LogStash::Util::Loggable

    def additionals_settings(settings)
      require "logstash/runner"
      logger.trace("Registering additional geoip settings")
      settings.register(LogStash::Setting::NullableString.new("xpack.geoip.download.endpoint"))
    rescue => e
      logger.error("Cannot register new settings", :message => e.message, :backtrace => e.backtrace)
      raise e
    end
  end
end end end