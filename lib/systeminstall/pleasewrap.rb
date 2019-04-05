# encoding: utf-8
$LOAD_PATH.unshift(File.expand_path(File.join(__FILE__, "..", "..")))

require "bootstrap/environment"

ENV["GEM_HOME"] = ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
Gem.use_paths(LogStash::Environment.logstash_gem_home)

#libdir = File.expand_path("../lib", File.dirname(__FILE__))
#$LOAD_PATH << libdir if File.exist?(File.join(libdir, "pleaserun", "cli.rb"))

require 'open3'

# Work around for https://github.com/elastic/logstash/issues/10593
# Issue on JRUBY https://github.com/jruby/jruby/issues/5642
# Workaround retrieved from https://github.com/jruby/jruby/issues/5642#issuecomment-479671017
if java.lang.System.getProperty("java.version").start_with?("11")
  if RUBY_ENGINE_VERSION != "9.2.6.0"
    raise "A workaround is in place for JRUBY-5642 that should be applied only to JRuby 9.2.6.0, but found #{RUBY_ENGINE_VERSION}"
  end
  class IO
    def self.pipe
      readwrite = Java::int[2].new
      JRuby.runtime.posix.pipe(readwrite)
      return readwrite.map do |fd|
        io = IO.for_fd(fd)
        io.close_on_exec = true
        io
      end
    end
  end
end

require "pleaserun/cli"
exit(PleaseRun::CLI.run || 0)
