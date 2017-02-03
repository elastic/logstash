# encoding: utf-8
require "logstash/errors"

module LogStash module BootstrapCheck
  class BadRuby
    def self.check(settings)
      if RUBY_VERSION < "1.9.2"
        raise LogStash::BootstrapCheckError, "Ruby 1.9.2 or later is required. (You are running: " + RUBY_VERSION + ")"
      end
    end
  end
end end
