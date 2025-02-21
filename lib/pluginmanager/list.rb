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

require 'rubygems/spec_fetcher'
require "pluginmanager/command"

class LogStash::PluginManager::List < LogStash::PluginManager::Command

  parameter "[PLUGIN]", "Part of plugin name to search for, leave empty for all plugins"

  option "--installed", :flag, "List only explicitly installed plugins using bin/logstash-plugin install ...", :default => false
  option "--[no-]expand", :flag, "Expand integration plugins and aliases", :default => true
  option "--verbose", :flag, "Also show plugin version number", :default => false
  option "--group", "NAME", "Filter plugins per group: input, output, filter, codec or integration" do |arg|
    raise(ArgumentError, "should be one of: input, output, filter, codec, integration") unless ['input', 'output', 'filter', 'codec', 'pack', 'integration'].include?(arg)
    arg
  end

  def execute
    LogStash::Bundler.setup!({:without => [:build, :development]})

    signal_error("No plugins found") if filtered_specs.empty?

    installed_plugin_names = filtered_specs.collect {|spec| spec.name}

    filtered_specs.sort_by {|spec| spec.name}.each do |spec|
      line = "#{spec.name}"
      line += " (#{spec.version})" if verbose?
      puts(line)
      if expand?
        active_aliases = LogStash::PluginManager.find_aliases(spec.name)
                                                .reject {|alias_name| installed_plugin_names.include?(alias_name)}
        display_children(active_aliases.map {|alias_name| "#{alias_name} (alias)"})

        if spec.metadata.fetch("logstash_group", "") == "integration"
          integration_plugins = spec.metadata.fetch("integration_plugins", "").split(",")
          display_children(integration_plugins)
        end
      end
    end
  end

  def display_children(children)
    if children.any?
      most, last = children[0...-1], children[-1]
      most.each do |entry|
        puts(" ├── #{entry}")
      end
      puts(" └── #{last}")
    end
  end

  def filtered_specs
    @filtered_specs ||= begin
                          # start with all locally installed plugin gems regardless of the Gemfile content
                          specs = LogStash::PluginManager.find_plugins_gem_specs

                          # apply filters
                          specs = specs.select {|spec| gemfile.find(spec.name)} if installed?
                          specs = specs.select {|spec| spec_matches_search?(spec) } if plugin
                          specs = specs.select {|spec| spec.metadata['logstash_group'] == group} if group

                          specs
                        end
  end

  def spec_matches_search?(spec)
    return true if spec.name =~ /#{plugin}/i
    if LogStash::PluginManager.integration_plugin_spec?(spec)
      LogStash::PluginManager.integration_plugin_provides(spec).any? do |provided_plugin|
        provided_plugin =~ /#{plugin}/i
      end
    end
  end
end # class Logstash::PluginManager
