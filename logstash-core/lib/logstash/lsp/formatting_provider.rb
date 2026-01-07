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
    # Provides document formatting for Logstash config files
    class FormattingProvider
      DEFAULT_TAB_SIZE = 2

      def initialize(document_manager)
        @documents = document_manager
      end

      # Format entire document
      # @param uri [String] document URI
      # @param options [Hash] formatting options (tabSize, insertSpaces)
      # @return [Array<Hash>] LSP TextEdit array
      def format(uri, options = {})
        content = @documents.get_content(uri)
        return [] unless content

        tab_size = options["tabSize"] || DEFAULT_TAB_SIZE
        use_spaces = options.fetch("insertSpaces", true)
        indent_char = use_spaces ? " " * tab_size : "\t"

        formatted = format_content(content, indent_char)

        # Return single edit replacing entire document
        lines = content.split("\n", -1)
        [{
          "range" => {
            "start" => { "line" => 0, "character" => 0 },
            "end" => { "line" => lines.length - 1, "character" => lines.last&.length || 0 }
          },
          "newText" => formatted
        }]
      end

      private

      def format_content(content, indent)
        lines = content.split("\n")
        result = []
        indent_level = 0
        in_multiline_string = false

        lines.each do |line|
          stripped = line.strip

          # Skip empty lines but preserve them
          if stripped.empty?
            result << ""
            next
          end

          # Handle comments
          if stripped.start_with?("#")
            result << (indent * indent_level) + stripped
            next
          end

          # Count braces to determine indent changes
          # First, adjust for closing braces at start of line
          leading_close = stripped.match(/^[\}\]]+/)
          if leading_close
            indent_level -= leading_close[0].length
            indent_level = 0 if indent_level < 0
          end

          # Format the line
          formatted_line = format_line(stripped, indent, indent_level)
          result << formatted_line

          # Adjust indent for next line based on braces in this line
          open_braces = stripped.count('{') + stripped.count('[')
          close_braces = stripped.count('}') + stripped.count(']')

          # Don't count braces we already accounted for
          if leading_close
            close_braces -= leading_close[0].length
          end

          indent_level += open_braces - close_braces
          indent_level = 0 if indent_level < 0
        end

        result.join("\n")
      end

      def format_line(line, indent, level)
        # Apply base indentation
        indented = (indent * level) + line

        # Normalize spacing around =>
        indented = indented.gsub(/\s*=>\s*/, " => ")

        # Normalize spacing inside braces (but not for empty braces)
        indented = indented.gsub(/\{\s+\}/, "{}")
        indented = indented.gsub(/\[\s+\]/, "[]")

        # Add space after { if followed by content
        indented = indented.gsub(/\{([^\s\}])/, '{ \1')

        # Add space before } if preceded by content
        indented = indented.gsub(/([^\s\{])\}/, '\1 }')

        indented
      end
    end
  end
end
