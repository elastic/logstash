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

require "bootstrap/environment"
require "bundler"
require "bundler/definition"
require "bundler/dependency"
require "bundler/dsl"
require "bundler/injector"
require "pluginmanager/gemfile"

# This class cannot be in the logstash namespace, because of the way the DSL
# class interact with the other libraries
module Bundler
  class LogstashUninstall
    attr_reader :gemfile_path, :lockfile_path

    def initialize(gemfile_path, lockfile_path)
      @gemfile_path = gemfile_path
      @lockfile_path = lockfile_path
    end

    # To be uninstalled the candidate gems need to be standalone.
    def dependants_gems(gem_name)
      builder = Dsl.new
      builder.eval_gemfile(::File.join(::File.dirname(gemfile_path), "original gemfile"), File.read(gemfile_path))
      definition = builder.to_definition(lockfile_path, {})

      definition.specs
        .select { |spec| spec.dependencies.collect(&:name).include?(gem_name) }
        .collect(&:name).sort.uniq
    end

    def uninstall!(gem_name)
      unfreeze_gemfile do
        dependencies_from = dependants_gems(gem_name)

        if dependencies_from.size > 0
          display_cant_remove_message(gem_name, dependencies_from)
          false
        else
          remove_gem(gem_name)
          true
        end
      end
    end

    def remove_gem(gem_name)
      builder = Dsl.new
      file = File.new(gemfile_path, "r+")

      gemfile = LogStash::Gemfile.new(file).load
      gemfile.remove(gem_name)
      builder.eval_gemfile(::File.join(::File.dirname(gemfile_path), "gemfile to changes"), gemfile.generate)

      definition = builder.to_definition(lockfile_path, {})
      definition.lock(lockfile_path)
      gemfile.save

      LogStash::PluginManager.ui.info("Successfully removed #{gem_name}")
    ensure
      file.close if file
    end

    def display_cant_remove_message(gem_name, dependencies_from)
        message = <<-eos
Failed to remove \"#{gem_name}\" because the following plugins or libraries depend on it:

* #{dependencies_from.join("\n* ")}
        eos
        LogStash::PluginManager.ui.info(message)
    end

    def unfreeze_gemfile
      Bundler.definition.ensure_equivalent_gemfile_and_lockfile(true) if Bundler.settings[:frozen]

      Bundler.settings.temporary(:frozen => false) do
        yield
      end
    end

    def self.uninstall!(gem_name, options = { :gemfile => LogStash::Environment::GEMFILE, :lockfile => LogStash::Environment::LOCKFILE })
      gemfile_path = options[:gemfile]
      lockfile_path = options[:lockfile]
      LogstashUninstall.new(gemfile_path, lockfile_path).uninstall!(gem_name)
    end
  end
end
