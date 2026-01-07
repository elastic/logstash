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
    # Provides Go to Definition and Find References for field references
    class ReferencesProvider
      # Field reference pattern: [fieldname] or [nested][field]
      FIELD_PATTERN = /\[([^\[\]]+)\]/

      def initialize(document_manager)
        @documents = document_manager
      end

      # Go to definition - find where a field is first defined/created
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @return [Hash, nil] LSP Location or nil
      def definition(uri, line, character)
        content = @documents.get_content(uri)
        return nil unless content

        # Get the field name at cursor
        field = get_field_at_position(content, line, character)
        return nil unless field

        # Find where this field is defined (created)
        definitions = find_field_definitions(content, field)
        return nil if definitions.empty?

        # Return first definition
        def_line, def_col = definitions.first
        {
          "uri" => uri,
          "range" => {
            "start" => { "line" => def_line, "character" => def_col },
            "end" => { "line" => def_line, "character" => def_col + field.length + 2 }
          }
        }
      end

      # Find all references to a field
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @param include_declaration [Boolean] include the definition
      # @return [Array<Hash>] LSP Location array
      def references(uri, line, character, include_declaration = true)
        content = @documents.get_content(uri)
        return [] unless content

        # Get the field name at cursor
        field = get_field_at_position(content, line, character)
        return [] unless field

        # Find all occurrences
        find_all_field_occurrences(content, field).map do |ref_line, ref_col|
          {
            "uri" => uri,
            "range" => {
              "start" => { "line" => ref_line, "character" => ref_col },
              "end" => { "line" => ref_line, "character" => ref_col + field.length + 2 }
            }
          }
        end
      end

      private

      def get_field_at_position(content, line, character)
        lines = content.split("\n")
        return nil if line >= lines.length

        line_content = lines[line]
        return nil if character >= line_content.length

        # Find field reference at or around cursor
        # Look for [fieldname] pattern
        line_content.scan(FIELD_PATTERN) do |match|
          field_name = match[0]
          match_start = $~.begin(0)
          match_end = $~.end(0)

          if character >= match_start && character <= match_end
            return field_name
          end
        end

        nil
      end

      def find_field_definitions(content, field_name)
        definitions = []
        lines = content.split("\n")

        # Patterns that define/create fields
        definition_patterns = [
          # mutate { add_field => { "[field]" => ... } }
          /add_field\s*=>\s*\{[^}]*\[#{Regexp.escape(field_name)}\]/,
          # mutate { rename => { "old" => "[field]" } }
          /rename\s*=>\s*\{[^}]*=>\s*"\[#{Regexp.escape(field_name)}\]"/,
          # mutate { copy => { "source" => "[field]" } }
          /copy\s*=>\s*\{[^}]*=>\s*"\[#{Regexp.escape(field_name)}\]"/,
          # grok { match => { "message" => "(?<field>...)" } }
          /\(\?<#{Regexp.escape(field_name)}>/,
          # date { target => "[field]" }
          /target\s*=>\s*"\[#{Regexp.escape(field_name)}\]"/,
          # json { target => "[field]" }
          # Various other plugins that create fields
        ]

        lines.each_with_index do |line, line_num|
          definition_patterns.each do |pattern|
            if line =~ pattern
              # Find the exact position of the field in the line
              if (match = line.match(/\[#{Regexp.escape(field_name)}\]/))
                definitions << [line_num, match.begin(0)]
              end
            end
          end
        end

        # If no explicit definitions found, first occurrence might be the definition
        if definitions.empty?
          lines.each_with_index do |line, line_num|
            if (match = line.match(/\[#{Regexp.escape(field_name)}\]/))
              definitions << [line_num, match.begin(0)]
              break
            end
          end
        end

        definitions
      end

      def find_all_field_occurrences(content, field_name)
        occurrences = []
        lines = content.split("\n")

        lines.each_with_index do |line, line_num|
          # Find all occurrences of [fieldname] in this line
          line.scan(/\[#{Regexp.escape(field_name)}\]/) do
            occurrences << [line_num, $~.begin(0)]
          end
        end

        occurrences
      end
    end
  end
end
