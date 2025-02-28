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

require "pluginmanager/command"
require 'set'
require 'rubygems/uninstaller'

class LogStash::PluginManager::Clean < LogStash::PluginManager::Command

  option "--dry-run", :flag, "If set, only report what would be deleted", :default => false

  def execute
    locked_gem_names = ::Bundler::LockfileParser.new(File.read(LogStash::Environment::LOCKFILE)).specs.map(&:full_name).to_set
    orphan_gem_specs = ::Gem::Specification.each
                                           .reject(&:stubbed?) # skipped stubbed (uninstalled) gems
                                           .reject(&:default_gem?) # don't touch jruby-included default gems
                                           .reject{ |spec| locked_gem_names.include?(spec.full_name) }
                                           .sort

    inactive_plugins, orphaned_dependencies = orphan_gem_specs.partition { |spec| LogStash::PluginManager.logstash_plugin_gem_spec?(spec) }

    # uninstall plugins first, to limit damage should one fail to uninstall
    inactive_plugins.each { |plugin| uninstall("inactive plugin", plugin) }
    orphaned_dependencies.each { |dep| uninstall("orphaned dependency", dep) }
  end

  def uninstall(desc, spec)
    full_desc = "#{desc} #{spec.name} (#{spec.version})"
    if dry_run?
      puts "would clean #{full_desc}"
    else
      uninstall_gem!(spec)
      puts "cleaned #{full_desc}"
    end
  end

  def uninstall_gem!(gem_spec)
    removal_options = { force: true, executables: true }
    Gem::DefaultUserInteraction.use_ui(debug? ? Gem::DefaultUserInteraction.ui : Gem::SilentUI.new) do
      Gem::Uninstaller.new(gem_spec.name, removal_options.merge(version: gem_spec.version)).uninstall
    end
  rescue Gem::InstallError => e
    fail "Failed to uninstall `#{gem_spec.full_name}`"
  end
end