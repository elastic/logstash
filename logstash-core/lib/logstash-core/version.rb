# encoding: utf-8

# The version of logstash core gem.
#
# sourced from a copy of the master versions.yml file, see logstash-core/logstash-core.gemspec
if !defined?(ALL_VERSIONS)
  require 'yaml'
  ALL_VERSIONS = YAML.load_file(File.expand_path("../../versions-gem-copy.yml", File.dirname(__FILE__)))
end

if !defined?(LOGSTASH_CORE_VERSION)
  # PACKAGE_SUFFIX is declared in the artifact namespace from artifacts.rake
  LOGSTASH_CORE_VERSION = defined?(PACKAGE_SUFFIX) ? "#{ALL_VERSIONS.fetch("logstash-core")}#{PACKAGE_SUFFIX}" : ALL_VERSIONS.fetch("logstash-core")
end
