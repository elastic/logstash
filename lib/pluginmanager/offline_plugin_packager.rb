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

require "pluginmanager/ui"
require "pluginmanager/errors"
require "bootstrap/environment"
require "bootstrap/util/compress"
require "paquet"
require "stud/temporary"
require "fileutils"

module LogStash module PluginManager
  class SpecificationHelpers
    WILDCARD = "*"
    WILDCARD_INTO_RE = ".*"

    def self.find_by_name_with_wildcards(pattern)
      re = transform_pattern_into_re(pattern)
      ::Gem::Specification.find_all.select do |specification|
        specification.name =~ re
      end
    end

    def self.transform_pattern_into_re(pattern)
      Regexp.new("^#{pattern.gsub(WILDCARD, WILDCARD_INTO_RE)}$")
    end
  end

  class OfflinePluginPackager
    LOGSTASH_DIR = "logstash"
    DEPENDENCIES_DIR = ::File.join(LOGSTASH_DIR, "dependencies")

    # To make sure we have the maximum compatibility
    # we will ignore theses gems and they won't be included in the pack
    IGNORE_GEMS_IN_PACK = %w(
      logstash-core
      logstash-core-plugin-api
      jar-dependencies
    )

    INVALID_PLUGINS_TO_EXPLICIT_PACK = IGNORE_GEMS_IN_PACK.collect { |name| /^#{name}/ } + [
      /mixin/
    ]

    def initialize(plugins_to_package, target)
      @plugins_to_package = Array(plugins_to_package)
      @target = target

      validate_plugins!
    end

    def validate_plugins!
      @plugins_to_package.each do |plugin_name|
        if INVALID_PLUGINS_TO_EXPLICIT_PACK.any? { |invalid_name| plugin_name =~ invalid_name }
          raise UnpackablePluginError, "Cannot explicitly pack `#{plugin_name}` for offline installation"
        end
      end
    end

    def generate_temporary_path
      Stud::Temporary.pathname
    end

    def explicitly_declared_plugins_specs
      @plugins_to_package.collect do |plugin_pattern|
        specs = SpecificationHelpers.find_by_name_with_wildcards(plugin_pattern)

        if specs.size > 0
          specs
        else
          raise LogStash::PluginManager::PluginNotFoundError, "Cannot find plugins matching: `#{plugin_pattern}`. Please install these before creating the offline pack"
        end
      end.flatten
    end

    def execute
      temp_path = generate_temporary_path
      packet_gem = Paquet::Gem.new(temp_path, LogStash::Environment::CACHE_PATH)

      explicit_plugins_specs = explicitly_declared_plugins_specs

      explicit_plugins_specs.each do |spec|
        packet_gem.add(spec.name)
      end

      IGNORE_GEMS_IN_PACK.each do |gem_name|
        packet_gem.ignore(gem_name)
      end

      packet_gem.pack

      prepare_package(explicit_plugins_specs, temp_path)
      LogStash::Util::Zip.compress(temp_path, @target)
    ensure
      FileUtils.rm_rf(temp_path)
    end

    def prepare_package(explicit_plugins, temp_path)
      FileUtils.mkdir_p(::File.join(temp_path, LOGSTASH_DIR))
      FileUtils.mkdir_p(::File.join(temp_path, DEPENDENCIES_DIR))

      explicit_path = ::File.join(temp_path, LOGSTASH_DIR)
      dependencies_path = ::File.join(temp_path, DEPENDENCIES_DIR)

      Dir.glob(::File.join(temp_path, "*.gem")).each do |gem_file|
        filename = ::File.basename(gem_file)

        if explicit_plugins.any? { |spec| filename =~ /^#{spec.name}/ }
          FileUtils.mv(gem_file, ::File.join(explicit_path, filename))
        else
          FileUtils.mv(gem_file, ::File.join(dependencies_path, filename))
        end
      end
    end

    def self.package(plugins_args, target)
      OfflinePluginPackager.new(plugins_args, target).execute
    end
  end
end end
