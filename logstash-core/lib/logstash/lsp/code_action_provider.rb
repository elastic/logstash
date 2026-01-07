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
  module Lsp
    # Provides code actions (quick fixes) for Logstash config files
    class CodeActionProvider
      # Code action kinds
      KIND_QUICKFIX = "quickfix"
      KIND_REFACTOR = "refactor"
      KIND_SOURCE = "source"

      def initialize(schema_provider, document_manager, diagnostics_provider)
        @schema = schema_provider
        @documents = document_manager
        @diagnostics = diagnostics_provider
      end

      # Get code actions for a range
      # @param uri [String] document URI
      # @param range [Hash] LSP Range
      # @param context [Hash] LSP CodeActionContext (includes diagnostics)
      # @return [Array<Hash>] LSP CodeAction array
      def code_actions(uri, range, context)
        actions = []
        diagnostics = context["diagnostics"] || []

        diagnostics.each do |diagnostic|
          message = diagnostic["message"]

          # "Did you mean 'X'?" suggestions
          if message =~ /Did you mean '([^']+)'\?/
            suggestion = $1
            actions << create_replace_action(
              "Change to '#{suggestion}'",
              uri,
              diagnostic["range"],
              suggestion
            )
          end

          # "Unknown option 'X'" - offer to remove
          if message =~ /Unknown option '([^']+)'/
            option = $1
            actions << create_remove_line_action(
              "Remove unknown option '#{option}'",
              uri,
              diagnostic["range"]["start"]["line"]
            )
          end

          # "Missing required option 'X'" - offer to add
          if message =~ /Missing required option '([^']+)' for (\w+)/
            option = $1
            plugin = $2
            actions.concat(create_add_option_actions(uri, diagnostic, option, plugin))
          end

          # Deprecated option - offer to remove
          if message =~ /deprecated/i
            actions << create_remove_line_action(
              "Remove deprecated option",
              uri,
              diagnostic["range"]["start"]["line"]
            )
          end
        end

        actions
      end

      private

      def create_replace_action(title, uri, range, new_text)
        {
          "title" => title,
          "kind" => KIND_QUICKFIX,
          "edit" => {
            "changes" => {
              uri => [{
                "range" => range,
                "newText" => new_text
              }]
            }
          }
        }
      end

      def create_remove_line_action(title, uri, line_num)
        content = @documents.get_content(uri)
        return nil unless content

        lines = content.split("\n")
        return nil if line_num >= lines.length

        # Remove the entire line including newline
        {
          "title" => title,
          "kind" => KIND_QUICKFIX,
          "edit" => {
            "changes" => {
              uri => [{
                "range" => {
                  "start" => { "line" => line_num, "character" => 0 },
                  "end" => { "line" => line_num + 1, "character" => 0 }
                },
                "newText" => ""
              }]
            }
          }
        }
      end

      def create_add_option_actions(uri, diagnostic, option, plugin)
        content = @documents.get_content(uri)
        return [] unless content

        lines = content.split("\n")
        diag_line = diagnostic["range"]["start"]["line"]

        # Find the plugin block to insert into
        # Look for the line with the plugin name
        plugin_line = nil
        lines.each_with_index do |line, idx|
          if line =~ /^\s*#{Regexp.escape(plugin)}\s*\{/
            plugin_line = idx
            break
          end
        end

        return [] unless plugin_line

        # Determine the indentation
        indent = "    "  # Default 4 spaces
        if lines[plugin_line + 1] =~ /^(\s+)/
          indent = $1
        end

        # Get option details for default value
        # Find section type
        section = find_section_for_line(lines, plugin_line)
        details = @schema.option_details(section, plugin, option) if section

        # Create placeholder based on type
        value_placeholder = create_value_placeholder(details)

        insert_line = plugin_line + 1
        new_text = "#{indent}#{option} => #{value_placeholder}\n"

        [{
          "title" => "Add required option '#{option}'",
          "kind" => KIND_QUICKFIX,
          "edit" => {
            "changes" => {
              uri => [{
                "range" => {
                  "start" => { "line" => insert_line, "character" => 0 },
                  "end" => { "line" => insert_line, "character" => 0 }
                },
                "newText" => new_text
              }]
            }
          }
        }]
      end

      def find_section_for_line(lines, target_line)
        section = nil
        lines.each_with_index do |line, idx|
          break if idx > target_line
          if line =~ /^\s*(input|filter|output)\s*\{/
            section = $1.to_sym
          end
        end
        section
      end

      def create_value_placeholder(details)
        return "\"\"" unless details

        case details[:type]
        when "string"
          details[:default] ? "\"#{details[:default]}\"" : "\"\""
        when "number"
          details[:default] || "0"
        when "boolean"
          details[:default] || "true"
        when "array"
          "[]"
        when "hash"
          "{ }"
        when Hash
          if details[:type][:enum]
            "\"#{details[:type][:enum].first}\""
          else
            "\"\""
          end
        else
          "\"\""
        end
      end
    end
  end
end
