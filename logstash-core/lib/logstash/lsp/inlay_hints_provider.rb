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
    # Provides inlay hints showing default values and type info
    class InlayHintsProvider
      # Inlay hint kinds
      KIND_TYPE = 1
      KIND_PARAMETER = 2

      def initialize(schema_provider, document_manager)
        @schema = schema_provider
        @documents = document_manager
      end

      # Get inlay hints for a range
      # @param uri [String] document URI
      # @param range [Hash] LSP Range
      # @return [Array<Hash>] LSP InlayHint array
      def inlay_hints(uri, range)
        content = @documents.get_content(uri)
        return [] unless content

        hints = []
        lines = content.split("\n")

        start_line = range["start"]["line"]
        end_line = range["end"]["line"]

        current_section = nil
        current_plugin = nil
        brace_depth = 0

        lines.each_with_index do |line, line_num|
          # Track section
          if line =~ /^\s*(input|filter|output)\s*\{/
            current_section = $1.to_sym
            brace_depth = 1
            current_plugin = nil
          elsif current_section
            # Track plugin at depth 1
            if brace_depth == 1 && line =~ /^\s*([a-z][a-z0-9_-]*)\s*\{/i
              current_plugin = $1
            end

            brace_depth += line.count('{')
            brace_depth -= line.count('}')

            if brace_depth == 1
              current_plugin = nil
            elsif brace_depth == 0
              current_section = nil
              current_plugin = nil
            end

            # Only process lines in the requested range
            next if line_num < start_line || line_num > end_line

            # Look for options in plugin blocks (depth 2)
            if current_section && current_plugin && line =~ /^\s*([a-z][a-z0-9_-]*)\s*=>/i
              option_name = $1
              details = @schema.option_details(current_section, current_plugin, option_name)

              if details
                # Add type hint after option name
                if details[:type]
                  col = line.index(option_name)
                  if col
                    hints << create_type_hint(line_num, col + option_name.length, details[:type])
                  end
                end

                # Add default value hint if option has one and value appears to use default
                if details[:default] && !has_explicit_value?(line)
                  hints << create_default_hint(line_num, line.length, details[:default])
                end
              end
            end
          end
        end

        hints
      end

      private

      def create_type_hint(line, character, type)
        {
          "position" => { "line" => line, "character" => character },
          "label" => ": #{format_type(type)}",
          "kind" => KIND_TYPE,
          "paddingLeft" => false,
          "paddingRight" => true
        }
      end

      def create_default_hint(line, character, default)
        {
          "position" => { "line" => line, "character" => character },
          "label" => " (default: #{default.inspect})",
          "kind" => KIND_PARAMETER,
          "paddingLeft" => true,
          "paddingRight" => false
        }
      end

      def format_type(type)
        case type
        when Hash
          if type[:enum]
            "enum"
          elsif type[:pattern]
            "pattern"
          else
            "any"
          end
        else
          type.to_s
        end
      end

      def has_explicit_value?(line)
        # Check if line has a value after =>
        line =~ /=>\s*\S/
      end
    end
  end
end
