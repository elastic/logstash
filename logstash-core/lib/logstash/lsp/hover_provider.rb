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

require "logstash/lsp/schema_provider"
require "logstash/lsp/document_manager"

module LogStash
  module Lsp
    # Provides hover information for Logstash config files
    class HoverProvider
      # Plugin-specific examples for better hover documentation
      PLUGIN_EXAMPLES = {
        "grok" => {
          "match" => '{ "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}" }',
          "patterns_dir" => '["/etc/logstash/patterns"]',
          "overwrite" => '["message"]'
        },
        "date" => {
          "match" => '["timestamp", "ISO8601", "yyyy-MM-dd HH:mm:ss"]',
          "target" => '"@timestamp"',
          "timezone" => '"UTC"'
        },
        "mutate" => {
          "rename" => '{ "old_field" => "new_field" }',
          "convert" => '{ "bytes" => "integer" }',
          "gsub" => '["field", "/", "_"]',
          "split" => '{ "tags" => "," }',
          "add_field" => '{ "new_field" => "value" }'
        },
        "elasticsearch" => {
          "hosts" => '["https://localhost:9200"]',
          "index" => '"logs-%{+YYYY.MM.dd}"',
          "user" => '"elastic"',
          "password" => '"changeme"',
          "ssl_certificate_authorities" => '["/path/to/ca.crt"]'
        },
        "file" => {
          "path" => '"/var/log/app/*.log"',
          "start_position" => '"beginning"',
          "sincedb_path" => '"/dev/null"'
        },
        "json" => {
          "source" => '"message"',
          "target" => '"parsed"'
        },
        "kv" => {
          "source" => '"message"',
          "field_split" => '" "',
          "value_split" => '"="'
        },
        "translate" => {
          "source" => '"status_code"',
          "target" => '"status_name"',
          "dictionary" => '{ "200" => "OK", "404" => "Not Found" }'
        }
      }.freeze

      SECTION_DOCS = {
        "input" => {
          title: "Input Section",
          description: "Input plugins define sources of events for Logstash to process. " \
                       "Each input plugin runs in its own thread and generates events " \
                       "that flow through the pipeline."
        },
        "filter" => {
          title: "Filter Section",
          description: "Filter plugins transform and enrich events as they pass through " \
                       "the pipeline. Filters are executed in order, and can modify, " \
                       "add, or remove fields from events."
        },
        "output" => {
          title: "Output Section",
          description: "Output plugins send events to external destinations such as " \
                       "Elasticsearch, files, or other systems. Multiple outputs can " \
                       "receive the same events."
        }
      }.freeze

      def initialize(schema_provider, document_manager)
        @schema = schema_provider
        @documents = document_manager
      end

      # Get hover information at a position
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @return [Hash, nil] LSP Hover object or nil
      def hover(uri, line, character)
        word_info = @documents.get_word_at(uri, line, character)
        return nil unless word_info

        word = word_info[:word]
        context = @documents.get_context_at(uri, line, character)

        content = generate_hover_content(word, context)
        return nil unless content

        {
          "contents" => {
            "kind" => "markdown",
            "value" => content
          },
          "range" => {
            "start" => { "line" => line, "character" => word_info[:start] },
            "end" => { "line" => line, "character" => word_info[:end] }
          }
        }
      end

      private

      def generate_hover_content(word, context)
        # Check if it's a section keyword
        if SECTION_DOCS.key?(word)
          return format_section_hover(word)
        end

        section = context[:section]
        plugin = context[:plugin]

        case context[:type]
        when :plugin_name, :section
          # Hovering over a plugin name
          if section && @schema.plugin_exists?(section, word)
            return format_plugin_hover(section, word)
          end
        when :plugin_block, :attribute_name
          # Check if word is a plugin name or attribute
          if section && plugin
            option = @schema.option_details(section, plugin, word)
            if option
              return format_option_hover(word, option, plugin)
            end
          end
          # Maybe hovering over the plugin name in the block
          if section && @schema.plugin_exists?(section, word)
            return format_plugin_hover(section, word)
          end
        when :attribute_value
          # Could show type information for values
          return nil
        end

        nil
      end

      def format_section_hover(keyword)
        info = SECTION_DOCS[keyword]
        <<~MARKDOWN
          ## #{info[:title]}

          #{info[:description]}

          ```logstash
          #{keyword} {
            plugin_name {
              option => value
            }
          }
          ```
        MARKDOWN
      end

      def format_plugin_hover(section, plugin_name)
        description = @schema.plugin_description(section, plugin_name)
        options = @schema.plugin_options(section, plugin_name)

        required_opts = options.select { |_, v| v[:required] }.keys
        common_opts = options.select { |_, v| v[:common] && !v[:required] }.keys.first(5)

        md = []
        md << "## #{plugin_name}"
        md << ""
        md << "*#{section} plugin*"
        md << ""
        md << description if description
        md << ""

        if required_opts.any?
          md << "### Required Options"
          md << ""
          required_opts.each do |opt|
            details = options[opt]
            md << "- `#{opt}` (#{format_type_short(details[:type])})"
          end
          md << ""
        end

        if common_opts.any?
          md << "### Common Options"
          md << ""
          common_opts.each do |opt|
            details = options[opt]
            default = details[:default] ? " = `#{details[:default].inspect}`" : ""
            md << "- `#{opt}` (#{format_type_short(details[:type])})#{default}"
          end
          md << ""
        end

        md << "```logstash"
        md << "#{plugin_name} {"
        required_opts.each { |opt| md << "  #{opt} => ..." }
        md << "}"
        md << "```"

        md.join("\n")
      end

      def format_option_hover(option_name, details, plugin_name)
        md = []
        md << "## #{option_name}"
        md << ""
        md << "*Option for #{plugin_name}*"
        md << ""

        if details[:required]
          md << "**Required**"
          md << ""
        end

        if details[:description]
          md << details[:description]
          md << ""
        end

        md << "| Property | Value |"
        md << "|----------|-------|"
        md << "| Type | #{format_type_short(details[:type])} |"

        if details[:default]
          md << "| Default | `#{details[:default].inspect}` |"
        end

        if details[:deprecated]
          md << ""
          md << "> ⚠️ **Deprecated**: This option is deprecated and may be removed in a future version."
        end

        # Get plugin-specific example or fall back to generic
        example = get_plugin_example(plugin_name, option_name) ||
                  example_value(details[:type], details[:default])

        md << ""
        md << "### Example"
        md << ""
        md << "```logstash"
        md << "#{plugin_name} {"
        md << "  #{option_name} => #{example}"
        md << "}"
        md << "```"

        md.join("\n")
      end

      def get_plugin_example(plugin_name, option_name)
        PLUGIN_EXAMPLES.dig(plugin_name, option_name)
      end

      def format_type_short(type)
        case type
        when Hash
          if type[:enum]
            type[:enum].map { |v| "`#{v}`" }.join(" | ")
          elsif type[:pattern]
            "pattern"
          else
            type.to_s
          end
        else
          type.to_s
        end
      end

      def example_value(type, default)
        return default.inspect if default

        case type
        when "string"
          '"example"'
        when "number"
          "123"
        when "boolean"
          "true"
        when "array"
          '["item1", "item2"]'
        when "hash"
          '{ "key" => "value" }'
        when "codec"
          "json"
        when Hash
          if type[:enum]
            "\"#{type[:enum].first}\""
          else
            "..."
          end
        else
          "..."
        end
      end
    end
  end
end
