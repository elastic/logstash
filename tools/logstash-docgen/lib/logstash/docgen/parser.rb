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

require "logstash/docgen/dynamic_parser"
require "logstash/docgen/static_parser"
require "logstash/docgen/asciidoc_format"
require "logstash/docgen/dependency_lookup"
require "rubygems/specification"
require "gems"
require "open-uri"
require "json"

module LogStash module Docgen
  class DefaultPlugins
    DEFAULT_PLUGINS_LIST_JSON = "https://raw.githubusercontent.com/ph/logstash/de2ba3f964ae7039b7b74a4a8212beb5a76a239c/rakelib/plugins-metadata.json"

    class << self
      def default_plugins_list
        @default_plugins_list ||= from_main_json
      end

      def include?(name)
        default_plugins_list.include?(name)
      end

      def from_main_json
        response = open(DEFAULT_PLUGINS_LIST_JSON)
        JSON.parse(response.read).select { |_, values| values["default-plugins"] == true }.keys
      end
    end
  end

  # This class acts as the transformation point between the format
  # and the data.
  #
  # At the beginning of the PoC, I was targeting multiples different format: asciidoc, manpage,
  # since we only support 1 format now, we could probably remove it.
  class Document
    attr_reader :context, :format

    def initialize(context, format)
      @context = context
      @format = format
    end

    def output
      @output ||= format.generate(context)
    end

    def save(directory, filename = nil)
      target_directory = ::File.join(directory, "#{context.section}s")
      FileUtils.mkdir_p(target_directory)

      filename = "#{context.config_name}.#{format.extension}" unless filename
      target = ::File.join(target_directory, filename)
      ::File.open(target, "w") { |f| f.write(output) }
    end
  end

  # This class is mostly a data class that represent what will be exposed in the ERB files
  # Less manipulation should be done in the ERB itself and most of the works should be done here
  class PluginContext
    ANCHOR_VERSION_RE = /\./
    LOGSTASH_PLUGINS_ORGANIZATION = "https://github.com/logstash-plugins"
    CANONICAL_NAME_PREFIX = "logstash"
    GLOBAL_BLOCKLIST = ["enable_metric", "id"]
    BLOCKLIST = {
      "input" => GLOBAL_BLOCKLIST + ["type", "debug", "format", "charset", "message_format", "codec", "tags", "add_field"],
      "codec" => GLOBAL_BLOCKLIST,
      "output" => GLOBAL_BLOCKLIST + ["type", "tags", "exclude_tags", "codec", "workers"],
      "filter" => GLOBAL_BLOCKLIST + ["type", "tags", "add_tag", "remove_tag", "add_field", "remove_field", "periodic_flush"]
    }

    attr_accessor :description, :config_name, :section, :name, :default_plugin, :gemspec

    def initialize(options = {})
      @config = {}
      @options = options
    end

    def default_plugin?
      DefaultPlugins.include?(canonical_name)
    end

    def has_description?
      !description.nil? && !description.empty?
    end

    def version
      gemspec.version.to_s
    end

    def release_date(format = "%B %-d, %Y")
      @release_date ||= begin
                          url = "https://rubygems.org/api/v1/versions/#{canonical_name}.json"
                          response = open(url).read
                          # HACK: One of out default plugins, the webhdfs, has a bad encoding in the gemspec
                          # which make our parser trip with this error:
                          #
                          # Encoding::UndefinedConversionError message: ""\xC3"" from ASCII-8BIT to UTF-8
                          # We dont have much choice than to force utf-8.
                          response.encode(Encoding::UTF_8, :invalid => :replace, :undef => :replace)

                          data = JSON.parse(response)

                          current_version = data.select { |v| v["number"] == version }.first
                          if current_version.nil?
                            "N/A"

                          else
                            Time.parse(current_version["created_at"]).strftime(format)
                          end
                        end
    end

    def add_config_description(name, description)
      @config[name] ||= { }
      @config[name].merge!({ :description => description })
    end

    def add_config_attributes(name, attributes = {})
      @config[name] ||= {}
      @config[name].merge!(attributes)
    end

    def canonical_name
      "#{CANONICAL_NAME_PREFIX}-#{section}-#{config_name}"
    end

    # Developer can declare options in the order they want
    # `Hash` keys are sorted by default in the order of creation.
    # But we force a sort options name for the documentation.
    def config
      Hash[@config.sort_by(&:first)].delete_if { |k, v| BLOCKLIST[section].include?(k) }
    end
    alias_method :sorted_attributes, :config

    def changelog_url
      # https://github.com/logstash-plugins/logstash-input-beats/blob/main/CHANGELOG.md#310beta3
      "#{LOGSTASH_PLUGINS_ORGANIZATION}/#{canonical_name}/blob/main/CHANGELOG.md##{anchor_version}"
    end

    def anchor_version
      version.gsub(ANCHOR_VERSION_RE, "")
    end

    def supported_logstash(max = 5)
      DependencyLookup.supported_logstash(gemspec)[0...max].join(", ")
    end

    # Used for making `variables` available inside
    # ERB templates.
    def get_binding
      binding
    end
  end

  # This class is the main point of entry to the parsing of the plugin ruby file,
  # the parser need to do 3 differents actions:
  #
  # 1. A Static Parsed of the comment of the files
  # 2. A Dynamic evaluation of the ruby code to get attributes and parent files
  # 3. A static parsing of the other modules included by the specific plugin
  class Parser
    # This is a multipass parser
    def self.parse(file, options = { :default_plugin => true })
      context = PluginContext.new(options)
      static = StaticParser.new(context)

      # Extract ancestors, classes and modules and retrieve the physical
      # location of the code for static parsing.
      dynamic = DynamicParser.new(context, file, static.extract_class_name(file))
      dynamic.parse

      # Static parse on the modules and parents classes
      # will update previously parsed context
      dynamic.extract_sources_location.each { |f| static.parse(f) }

      # Static parse on the target file,
      # Can override parents documentation. We are making the assumption that
      # the modules are declared at the top of the class.
      static.parse(file, true)
      context
    end
  end

  def self.generate_for_plugin(plugin_source_path, options = {})
    gemspec = load_plugin_specification(plugin_source_path)
    _, type, name = gemspec.name.split("-")

    file = "#{plugin_source_path}/lib/logstash/#{type}s/#{name}.rb"

    format = LogStash::Docgen::AsciidocFormat.new(options)

    context = LogStash::Docgen::Parser.parse(file)
    context.gemspec = gemspec
    Document.new(context, format)
  end

  # Note that Gem::Specification has an internal cache.
  def self.load_plugin_specification(plugin_source_path)
    gemspec = Dir.glob(::File.join(plugin_source_path, "*.gemspec")).first
    raise "Cannot find the gemspec in #{plugin_source_path}" if gemspec.nil?
    Gem::Specification.load(gemspec)
  end
end end
