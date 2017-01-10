# encoding: utf-8
require "logstash/util"
require "logstash/util/java_version"
require "logstash/errors"

module LogStash module BootstrapCheck
  class BadJava
    def self.check(settings)
      # Exit on bad java versions
      LogStash::Util::JavaVersion.validate_java_version!
    rescue => e
      # Just rewrap the original exception
      raise LogStash::BootstrapCheckError, e.message
    end
  end
end end
