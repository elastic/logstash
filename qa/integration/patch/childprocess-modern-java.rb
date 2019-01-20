# encoding: utf-8

# Implementation of ChildProcess::JRuby::Process#pid depends heavily on
# what Java SDK is being used; here, we look it up once at load, then
# override that method with an implementation that works on modern Javas
# if necessary.
#
# This patch can be removed when the upstream childprocess gem supports Java 9+
# https://github.com/enkessler/childprocess/pull/141
normalised_java_version_major = java.lang.System.get_property("java.version")
                                    .slice(/^(1\.)?([0-9]+)/, 2)
                                    .to_i

if normalised_java_version_major >= 9
  $stderr.puts("patching childprocess for Java9+ support...")
  ChildProcess::JRuby::Process.class_exec do
    def pid
      @process.pid
    rescue java.lang.UnsupportedOperationException => e
      raise NotImplementedError, "pid is not supported on this platform: #{e.message}"
    end
  end
end