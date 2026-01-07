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
    # Provides completion suggestions for Logstash config files
    class CompletionProvider
      # LSP Completion Item Kinds
      KIND_TEXT = 1
      KIND_METHOD = 2
      KIND_FUNCTION = 3
      KIND_CONSTRUCTOR = 4
      KIND_FIELD = 5
      KIND_VARIABLE = 6
      KIND_CLASS = 7
      KIND_INTERFACE = 8
      KIND_MODULE = 9
      KIND_PROPERTY = 10
      KIND_UNIT = 11
      KIND_VALUE = 12
      KIND_ENUM = 13
      KIND_KEYWORD = 14
      KIND_SNIPPET = 15
      KIND_COLOR = 16
      KIND_FILE = 17
      KIND_REFERENCE = 18
      KIND_FOLDER = 19
      KIND_ENUM_MEMBER = 20
      KIND_CONSTANT = 21
      KIND_STRUCT = 22
      KIND_EVENT = 23
      KIND_OPERATOR = 24
      KIND_TYPE_PARAMETER = 25

      SECTION_KEYWORDS = %w[input filter output].freeze

      def initialize(schema_provider, document_manager)
        @schema = schema_provider
        @documents = document_manager
      end

      # Get completions at a position
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @return [Hash] LSP CompletionList
      def complete(uri, line, character)
        context = @documents.get_context_at(uri, line, character)

        items = case context[:type]
                when :root
                  complete_root(context)
                when :section
                  complete_section(context)
                when :plugin_name
                  complete_plugin_name(context)
                when :plugin_block, :attribute_name
                  complete_attribute_name(context)
                when :attribute_value
                  complete_attribute_value(context)
                else
                  []
                end

        # Filter by current word prefix if present
        # Only filter for plugin names and root completions, not attribute names
        # (users want to see all options when inside a plugin block)
        if context[:current_word] && !context[:current_word].empty?
          if context[:type] == :plugin_name || context[:type] == :root
            prefix = context[:current_word].downcase
            items = items.select { |item|
              label = item["filterText"] || item["label"]
              label.downcase.start_with?(prefix)
            }
          end
        end

        {
          "isIncomplete" => false,
          "items" => items
        }
      end

      private

      def complete_root(context)
        # At root level, suggest section keywords
        SECTION_KEYWORDS.map do |keyword|
          {
            "label" => keyword,
            "kind" => KIND_KEYWORD,
            "detail" => "#{keyword.capitalize} section",
            "insertText" => "#{keyword} {\n  $0\n}",
            "insertTextFormat" => 2,  # Snippet
            "documentation" => section_documentation(keyword)
          }
        end
      end

      def complete_section(context)
        # Inside a section, suggest plugins
        complete_plugin_name(context)
      end

      def complete_plugin_name(context)
        section = context[:section]
        return [] unless section

        plugins = @schema.plugin_names(section)
        plugins.map do |plugin_name|
          desc = @schema.plugin_description(section, plugin_name)
          {
            "label" => plugin_name,
            "kind" => KIND_MODULE,
            "detail" => "#{section} plugin",
            "insertText" => "#{plugin_name} {\n  $0\n}",
            "insertTextFormat" => 2,  # Snippet
            "documentation" => desc
          }
        end.sort_by { |item| item["label"] }
      end

      def complete_attribute_name(context)
        section = context[:section]
        plugin = context[:plugin]
        return [] unless section && plugin

        options = @schema.plugin_options(section, plugin)
        return [] unless options

        # Sort: required first, then non-common, then common
        sorted_options = options.sort_by do |name, details|
          priority = 0
          priority -= 100 if details[:required]
          priority += 50 if details[:common]
          [priority, name]
        end

        sorted_options.map do |name, details|
          item = {
            "label" => name,
            "kind" => KIND_PROPERTY,
            "detail" => format_type(details[:type]),
            "documentation" => format_option_documentation(name, details)
          }

          # Add required indicator
          if details[:required]
            item["label"] = "#{name} (required)"
            item["filterText"] = name
            item["sortText"] = "0#{name}"
          end

          # Add deprecation warning
          if details[:deprecated]
            item["deprecated"] = true
            item["tags"] = [1]  # LSP deprecated tag
          end

          # Create insert text based on type
          item["insertText"] = create_attribute_snippet(name, details)
          item["insertTextFormat"] = 2  # Snippet

          item
        end
      end

      def complete_attribute_value(context)
        section = context[:section]
        plugin = context[:plugin]
        return [] unless section && plugin

        # Try to determine which attribute we're completing
        # This is simplified - a full implementation would parse the line
        attribute = find_current_attribute(context)
        return [] unless attribute

        details = @schema.option_details(section, plugin, attribute)
        return [] unless details

        type = details[:type]

        case type
        when Hash
          if type[:enum]
            # Enumerated values
            type[:enum].map do |value|
              {
                "label" => value.to_s,
                "kind" => KIND_ENUM_MEMBER,
                "insertText" => "\"#{value}\""
              }
            end
          else
            []
          end
        when "boolean"
          [
            { "label" => "true", "kind" => KIND_KEYWORD },
            { "label" => "false", "kind" => KIND_KEYWORD }
          ]
        when "codec"
          # Suggest codec plugins
          @schema.plugin_names(:codec).map do |codec_name|
            {
              "label" => codec_name,
              "kind" => KIND_MODULE,
              "insertText" => codec_name
            }
          end
        else
          # For other types, provide type hint
          type_completions(type, details[:default])
        end
      end

      def format_type(type)
        case type
        when Hash
          if type[:enum]
            "enum: #{type[:enum].join(' | ')}"
          elsif type[:pattern]
            "pattern: /#{type[:pattern]}/"
          else
            type.to_s
          end
        else
          type.to_s
        end
      end

      def format_option_documentation(name, details)
        doc = []
        doc << details[:description] if details[:description]
        doc << ""
        doc << "**Type:** #{format_type(details[:type])}"
        doc << "**Default:** `#{details[:default].inspect}`" if details[:default]
        doc << "**Required:** yes" if details[:required]
        doc << "**Deprecated**" if details[:deprecated]

        {
          "kind" => "markdown",
          "value" => doc.join("\n")
        }
      end

      def create_attribute_snippet(name, details)
        type = details[:type]
        value_placeholder = case type
                           when "string"
                             "\"$1\""
                           when "number"
                             "${1:0}"
                           when "boolean"
                             "${1|true,false|}"
                           when "array"
                             "[$1]"
                           when "hash"
                             "{ $1 }"
                           when Hash
                             if type[:enum]
                               choices = type[:enum].map { |v| "\"#{v}\"" }.join(",")
                               "${1|#{choices}|}"
                             else
                               "$1"
                             end
                           else
                             "$1"
                           end

        "#{name} => #{value_placeholder}"
      end

      def section_documentation(keyword)
        docs = {
          "input" => "Define input sources that bring data into Logstash",
          "filter" => "Transform and enrich events as they pass through",
          "output" => "Send events to external destinations"
        }

        {
          "kind" => "markdown",
          "value" => docs[keyword] || ""
        }
      end

      def find_current_attribute(context)
        # Parse the current line to find which attribute we're completing a value for
        line_text = context[:line_text]
        return nil unless line_text

        # Look for pattern: attribute_name => (cursor here)
        # Match: "  codec => " or "match => {" etc.
        if line_text =~ /^\s*([a-z][a-z0-9_-]*)\s*=>/i
          $1
        else
          nil
        end
      end

      def type_completions(type, default)
        items = []

        case type
        when "string"
          items << {
            "label" => '""',
            "kind" => KIND_VALUE,
            "insertText" => "\"$1\"",
            "insertTextFormat" => 2
          }
        when "number"
          items << {
            "label" => "0",
            "kind" => KIND_VALUE,
            "insertText" => "${1:0}",
            "insertTextFormat" => 2
          }
        when "array"
          items << {
            "label" => "[]",
            "kind" => KIND_VALUE,
            "insertText" => "[$1]",
            "insertTextFormat" => 2
          }
        when "hash"
          items << {
            "label" => "{}",
            "kind" => KIND_VALUE,
            "insertText" => "{ $1 }",
            "insertTextFormat" => 2
          }
        end

        if default
          items << {
            "label" => default.inspect,
            "kind" => KIND_VALUE,
            "detail" => "default value"
          }
        end

        items
      end
    end
  end
end
