module LogStash
  module RakeLib

    # @return [Array<String>] list of all plugin names as defined in the logstash-plugins github organization, minus names that matches the ALL_PLUGINS_SKIP_LIST
    def self.fetch_all_plugins
      require 'octokit'
      Octokit.auto_paginate = true
      repos = Octokit.organization_repositories("logstash-plugins")
      repos.map(&:name).reject do |name|
        name =~ ALL_PLUGINS_SKIP_LIST || !is_released?(name)
      end
    end

    def self.is_released?(plugin)
      require 'gems'
      Gems.info(plugin) != "This rubygem could not be found."
    end

    def self.fetch_plugins_for(type)
      # Lets use the standard library here, in the context of the bootstrap the
      # logstash-core could have failed to be installed.
      require "json"
      JSON.load(::File.read("rakelib/plugins-metadata.json")).select do |_, metadata|
        metadata[type]
      end.keys
    end

    # plugins included by default in the logstash distribution
    DEFAULT_PLUGINS = self.fetch_plugins_for("default-plugins").freeze

    # plugins required to run the logstash core specs
    CORE_SPECS_PLUGINS = self.fetch_plugins_for("core-specs").freeze

    TEST_JAR_DEPENDENCIES_PLUGINS = self.fetch_plugins_for("test-jar-dependencies").freeze

    TEST_VENDOR_PLUGINS = self.fetch_plugins_for("test-vendor-plugin").freeze

    ALL_PLUGINS_SKIP_LIST = Regexp.union(self.fetch_plugins_for("skip-list")).freeze

  end
end
