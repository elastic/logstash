# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
    rescue Gems::NotFound => e
      puts "Could not find gem #{plugin}"
      false
    end

    def self.fetch_plugins_for(type)
      # Lets use the standard library here, in the context of the bootstrap the
      # logstash-core could have failed to be installed.
      require "json"
      JSON.parse(::File.read("rakelib/plugins-metadata.json")).select do |_, metadata|
        metadata[type]
      end.keys
    end

    # plugins included by default in the logstash distribution
    DEFAULT_PLUGINS = self.fetch_plugins_for("default-plugins").freeze

    # plugins required to run the logstash core specs
    CORE_SPECS_PLUGINS = self.fetch_plugins_for("core-specs").freeze

    ALL_PLUGINS_SKIP_LIST = Regexp.union(self.fetch_plugins_for("skip-list")).freeze

    # default plugins will be installed and we exclude only installed plugins from OSS
    OSS_EXCLUDED_PLUGINS = DEFAULT_PLUGINS & self.fetch_plugins_for("skip-oss")
  end
end
