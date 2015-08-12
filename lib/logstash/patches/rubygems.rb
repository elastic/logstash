# encoding: utf-8
# monkey patch RubyGems to silence ffi warnings:
#
# WARN: Unresolved specs during Gem::Specification.reset:
#       ffi (>= 0)
# WARN: Clearing out unresolved specs.
# Please report a bug if this causes problems.
#
# see https://github.com/elasticsearch/logstash/issues/2556 and https://github.com/rubygems/rubygems/issues/1070
#
# this code is from Rubygems v2.1.9 in JRuby 1.7.17. Per tickets this issue should be solved at JRuby >= 1.7.20.
#
# this method implementation works for Rubygems version 2.1.0 and up, verified up to 2.4.6
if ::Gem::Version.new(::Gem::VERSION) >= ::Gem::Version.new("2.1.0") && ::Gem::Version.new(::Gem::VERSION) < ::Gem::Version.new("2.5.0")
  class ::Gem::Specification
    def self.reset
      @@dirs = nil
      ::Gem.pre_reset_hooks.each { |hook| hook.call }
      @@all = nil
      @@stubs = nil
      _clear_load_cache
      unresolved = unresolved_deps
      unless unresolved.empty?
        unless (unresolved.size == 1 && unresolved["ffi"])
          w = "W" + "ARN"
          warn "#{w}: Unresolved specs during Gem::Specification.reset:"
          unresolved.values.each do |dep|
            warn "      #{dep}"
          end
          warn "#{w}: Clearing out unresolved specs."
          warn "Please report a bug if this causes problems."
        end
        unresolved.clear
      end
      ::Gem.post_reset_hooks.each { |hook| hook.call }
    end
  end
end
