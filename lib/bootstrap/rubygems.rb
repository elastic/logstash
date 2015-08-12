# encoding: utf-8
module LogStash
  module Rubygems
    extend self

    def patch!
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
        ::Gem::Specification.class_exec do
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
    end

    # Take a gem package and extract it to a specific target
    # @param [String] Gem file, this must be a path
    # @param [String, String] Return a Gem::Package and the installed path
    def unpack(file, path)
      require "rubygems/package"
      require "securerandom"

      # We are creating a random directory per extract,
      # if we dont do this bundler will not trigger download of the dependencies.
      # Use case is:
      # - User build his own gem with a fix
      # - User doesnt increment the version
      # - User install the same version but different code or dependencies multiple times..
      basename  = ::File.basename(file, '.gem')
      unique = SecureRandom.hex(4)
      target_path = ::File.expand_path(::File.join(path, unique, basename))

      package = ::Gem::Package.new(file)
      package.extract_files(target_path)

      return [package, target_path]
    end

  end
end
