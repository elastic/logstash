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
    # Provides document symbols (outline) for Logstash config files
    class DocumentSymbolsProvider
      # LSP Symbol Kinds
      SYMBOL_FILE = 1
      SYMBOL_MODULE = 2
      SYMBOL_NAMESPACE = 3
      SYMBOL_PACKAGE = 4
      SYMBOL_CLASS = 5
      SYMBOL_METHOD = 6
      SYMBOL_PROPERTY = 7
      SYMBOL_FIELD = 8
      SYMBOL_CONSTRUCTOR = 9
      SYMBOL_ENUM = 10
      SYMBOL_INTERFACE = 11
      SYMBOL_FUNCTION = 12
      SYMBOL_VARIABLE = 13
      SYMBOL_CONSTANT = 14
      SYMBOL_STRING = 15
      SYMBOL_NUMBER = 16
      SYMBOL_BOOLEAN = 17
      SYMBOL_ARRAY = 18
      SYMBOL_OBJECT = 19
      SYMBOL_KEY = 20
      SYMBOL_NULL = 21
      SYMBOL_ENUM_MEMBER = 22
      SYMBOL_STRUCT = 23
      SYMBOL_EVENT = 24
      SYMBOL_OPERATOR = 25
      SYMBOL_TYPE_PARAMETER = 26

      def initialize(schema_provider, document_manager)
        @schema = schema_provider
        @documents = document_manager
      end

      # Get document symbols
      # @param uri [String] document URI
      # @return [Array<Hash>] LSP DocumentSymbol array
      def document_symbols(uri)
        content = @documents.get_content(uri)
        return [] unless content

        parse_symbols(content)
      end

      private

      def parse_symbols(content)
        symbols = []
        lines = content.split("\n")

        current_section = nil
        section_start_line = nil
        section_symbols = []

        current_plugin = nil
        plugin_start_line = nil
        plugin_symbols = []

        brace_depth = 0

        lines.each_with_index do |line, line_num|
          # Track sections (input/filter/output)
          if line =~ /^\s*(input|filter|output)\s*\{/
            # Close previous section if any
            if current_section
              symbols << create_section_symbol(
                current_section,
                section_start_line,
                line_num - 1,
                lines,
                section_symbols
              )
            end

            current_section = $1
            section_start_line = line_num
            section_symbols = []
            brace_depth = 1

          elsif current_section
            # Count braces
            open_braces = line.count('{')
            close_braces = line.count('}')

            # Check for plugin at depth 1
            if brace_depth == 1 && line =~ /^\s*([a-z][a-z0-9_-]*)\s*\{/i
              # Close previous plugin if any
              if current_plugin
                section_symbols << create_plugin_symbol(
                  current_plugin,
                  plugin_start_line,
                  line_num - 1,
                  lines,
                  plugin_symbols
                )
              end

              current_plugin = $1
              plugin_start_line = line_num
              plugin_symbols = []

            elsif brace_depth == 2 && current_plugin
              # Check for attributes inside plugin
              if line =~ /^\s*([a-z][a-z0-9_-]*)\s*=>/i
                attr_name = $1
                plugin_symbols << create_attribute_symbol(attr_name, line_num, line)
              end
            end

            brace_depth += open_braces
            brace_depth -= close_braces

            # Close plugin when returning to depth 1
            if brace_depth == 1 && current_plugin
              section_symbols << create_plugin_symbol(
                current_plugin,
                plugin_start_line,
                line_num,
                lines,
                plugin_symbols
              )
              current_plugin = nil
              plugin_symbols = []
            end

            # Close section when returning to depth 0
            if brace_depth == 0
              symbols << create_section_symbol(
                current_section,
                section_start_line,
                line_num,
                lines,
                section_symbols
              )
              current_section = nil
              section_symbols = []
            end
          end
        end

        # Handle unclosed section at end of file
        if current_section
          if current_plugin
            section_symbols << create_plugin_symbol(
              current_plugin,
              plugin_start_line,
              lines.length - 1,
              lines,
              plugin_symbols
            )
          end
          symbols << create_section_symbol(
            current_section,
            section_start_line,
            lines.length - 1,
            lines,
            section_symbols
          )
        end

        symbols
      end

      def create_section_symbol(name, start_line, end_line, lines, children)
        {
          "name" => name,
          "kind" => SYMBOL_NAMESPACE,
          "range" => range(start_line, 0, end_line, lines[end_line]&.length || 0),
          "selectionRange" => range(start_line, 0, start_line, name.length),
          "children" => children
        }
      end

      def create_plugin_symbol(name, start_line, end_line, lines, children)
        {
          "name" => name,
          "kind" => SYMBOL_CLASS,
          "range" => range(start_line, 0, end_line, lines[end_line]&.length || 0),
          "selectionRange" => range(start_line, (lines[start_line] =~ /#{name}/) || 0, start_line, ((lines[start_line] =~ /#{name}/) || 0) + name.length),
          "children" => children
        }
      end

      def create_attribute_symbol(name, line_num, line)
        col = line.index(name) || 0
        {
          "name" => name,
          "kind" => SYMBOL_PROPERTY,
          "range" => range(line_num, 0, line_num, line.length),
          "selectionRange" => range(line_num, col, line_num, col + name.length)
        }
      end

      def range(start_line, start_char, end_line, end_char)
        {
          "start" => { "line" => start_line, "character" => start_char },
          "end" => { "line" => end_line, "character" => end_char }
        }
      end
    end
  end
end
