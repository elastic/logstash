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

require "singleton"
require "gems"

module LogStash module Docgen
  class DependencyLookup
    LOGSTASH_CORE_PLUGIN_API_GEM = "logstash-core-plugin-api"
    LOGSTASH_CORE_GEM = "logstash-core"
    PRERELEASES_RE = /\.(alpha|snapshot|pre|beta).+/

    include Singleton

    def supported_logstash(gemspec)
      plugin_core_api_dep = gemspec.dependencies.select { |spec| spec.name.eql?(LOGSTASH_CORE_PLUGIN_API_GEM) }.first

      core_requirements = match_core_requirements(plugin_core_api_dep.requirement)
      clean_versions(match_core(core_requirements))
    end

    def self.supported_logstash(gemspec)
      instance.supported_logstash(gemspec)
    end

    private
    def match_core_requirements(requirements)
      logstash_core_plugin_api_versions.collect do |plugin|
        requirements.satisfied_by?(Gem::Version.new(plugin[:number]))
        dependencies = plugin[:dependencies].select { |dependency|  dependency.first == LOGSTASH_CORE_GEM }.collect(&:last)
      end.flatten.collect do |requirement|
          Gem::Requirement.new(requirement.split(", "))
      end.compact
    end

    def match_core(requirements)
      logstash_core_versions
        .collect { |plugin| Gem::Version.new(plugin[:number]) }
        .select { |v| requirements.any? { |requirement| requirement.satisfied_by?(v) } }
    end

    # Remove betas/alphas and reverse sort
    def clean_versions(gemspecs)
      gemspecs.collect(&:to_s)
        .collect { |v| v.gsub(PRERELEASES_RE, '') } # remove beta, alphas and snapshots
        .uniq
        .collect { |v| Gem::Version.new(v) }
        .sort { |x, y| y <=> x}
        .map(&:to_s)
    end

    def logstash_core_plugin_api_versions
      @logstash_core_plugin_api_version ||= Gems.dependencies(LOGSTASH_CORE_PLUGIN_API_GEM)
    end

    def logstash_core_versions
      @logstash_core_versions ||= Gems.dependencies(LOGSTASH_CORE_GEM)
    end
  end
end end
