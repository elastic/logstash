# encoding: utf-8
require "logstash/util"
require "logstash/util/java_version"
require "logstash/errors"

module LogStash module BootstrapCheck
  class BadJava
    def self.check(settings)
      # Exit on bad java versions
      java_version = LogStash::Util::JavaVersion.version

      if LogStash::Util::JavaVersion.bad_java_version?(java_version)
        raise LogStash::BootstrapCheckError, "Java version 1.8.0 or later is required. (You are running: #{java_version})"
      end
    end
  end
end end
