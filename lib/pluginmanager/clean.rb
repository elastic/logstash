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

class LogStash::PluginManager::Clean < LogStash::PluginManager::Command

  option "--dry-run", :flag, "If set, only report what would be deleted", :default => false

  def execute
    locked_gem_names = ::Bundler::LockfileParser.new(File.read(LogStash::Environment::LOCKFILE)).specs.map(&:full_name).to_set
    orphan_gem_specs = ::Gem::Specification.each
                                           .reject(&:default_gem?) # don't touch jruby-included default gems
                                           .reject{ |spec| locked_gem_names.include?(spec.full_name) }
                                           .sort

    file_list = orphan_gem_specs.map { |spec| get_gem_files(spec) }.flatten

    if dry_run?
      verb = "would clean"
      $stderr.puts("would remove files[")
      $stderr.puts(file_list)
      $stderr.puts("]")
    else
      verb = "cleaned"
      FileUtils.rm_rf(file_list)
    end

    inactive_plugins, orphaned_dependencies = orphan_gem_specs.partition { |spec| LogStash::PluginManager.logstash_plugin_gem_spec?(spec) }
    inactive_plugins.each { |spec| puts("#{verb} inactive plugin #{spec.name} (#{spec.version})") }
    orphaned_dependencies.each { |spec| puts("#{verb} orphaned dependency #{spec.name} (#{spec.version})") }
  end

  def get_gem_files(spec)
    %w(
      full_gem_path
      loaded_from
      spec_file
      cache_file
      build_info_file
      doc_dir
    ).map { |attr| spec.public_send(attr) }
     .compact
     .uniq
     .select { |path| File.exist?(path) }
  end
end