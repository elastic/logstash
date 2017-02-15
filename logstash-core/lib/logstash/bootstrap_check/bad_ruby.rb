# encoding: utf-8
require "logstash/errors"

module LogStash module BootstrapCheck
  class BadRuby
    def self.check(settings)
      if RUBY_VERSION < "2.0"
        raise LogStash::BootstrapCheckError, "Ruby 2.0 or later is required. (You are running: " + RUBY_VERSION + ")"
      end
    end
  end
end end
