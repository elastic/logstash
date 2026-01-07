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
    # Provides signature help (parameter hints) for Logstash config options
    class SignatureHelpProvider
      def initialize(schema_provider, document_manager)
        @schema = schema_provider
        @documents = document_manager
      end

      # Get signature help at a position
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @return [Hash, nil] LSP SignatureHelp or nil
      def signature_help(uri, line, character)
        content = @documents.get_content(uri)
        return nil unless content

        lines = content.split("\n")
        return nil if line >= lines.length

        line_content = lines[line]

        # Check if we're after a "=>" on this line
        arrow_match = line_content.match(/(\w+)\s*=>\s*$/)
        return nil unless arrow_match

        option_name = arrow_match[1]

        # Get context to find plugin and section
        context = @documents.get_context_at(uri, line, character)
        return nil unless context[:section] && context[:plugin]

        # Get option details
        details = @schema.option_details(context[:section], context[:plugin], option_name)
        return nil unless details

        create_signature_help(option_name, details)
      end

      private

      def create_signature_help(option_name, details)
        type_str = format_type(details[:type])
        label = "#{option_name} => #{type_str}"

        doc_parts = []
        doc_parts << details[:description] if details[:description]
        doc_parts << ""
        doc_parts << "**Type:** #{type_str}"
        doc_parts << "**Default:** `#{details[:default].inspect}`" if details[:default]
        doc_parts << "**Required:** yes" if details[:required]

        {
          "signatures" => [{
            "label" => label,
            "documentation" => {
              "kind" => "markdown",
              "value" => doc_parts.join("\n")
            },
            "parameters" => [{
              "label" => type_str,
              "documentation" => value_documentation(details[:type])
            }]
          }],
          "activeSignature" => 0,
          "activeParameter" => 0
        }
      end

      def format_type(type)
        case type
        when Hash
          if type[:enum]
            type[:enum].map { |v| "\"#{v}\"" }.join(" | ")
          elsif type[:pattern]
            "pattern"
          else
            type.to_s
          end
        else
          type.to_s
        end
      end

      def value_documentation(type)
        case type
        when "string"
          "A string value, e.g., `\"value\"`"
        when "number"
          "A numeric value, e.g., `123` or `45.67`"
        when "boolean"
          "Either `true` or `false`"
        when "array"
          "An array, e.g., `[\"a\", \"b\", \"c\"]`"
        when "hash"
          "A hash/object, e.g., `{ \"key\" => \"value\" }`"
        when "codec"
          "A codec plugin name, e.g., `json` or `plain`"
        when Hash
          if type[:enum]
            "One of: #{type[:enum].map { |v| "`#{v}`" }.join(", ")}"
          else
            "A value"
          end
        else
          "A value of type #{type}"
        end
      end
    end
  end
end
