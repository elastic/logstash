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
    # Provides semantic tokens for enhanced syntax highlighting
    class SemanticTokensProvider
      # Token types - must match the legend sent in capabilities
      TOKEN_TYPES = [
        "namespace",    # 0 - sections (input/filter/output)
        "class",        # 1 - plugin names
        "property",     # 2 - option names
        "string",       # 3 - string values
        "number",       # 4 - numeric values
        "keyword",      # 5 - keywords (if/else/and/or)
        "operator",     # 6 - operators (=>, ==, etc)
        "variable",     # 7 - field references [field]
        "comment",      # 8 - comments
        "regexp",       # 9 - regular expressions
        "type",         # 10 - type annotations
        "parameter"     # 11 - parameters
      ].freeze

      # Token modifiers
      TOKEN_MODIFIERS = [
        "declaration",   # 0
        "definition",    # 1
        "deprecated",    # 2
        "readonly"       # 3
      ].freeze

      def initialize(schema_provider, document_manager)
        @schema = schema_provider
        @documents = document_manager
      end

      # Get semantic tokens legend (sent once in capabilities)
      def legend
        {
          "tokenTypes" => TOKEN_TYPES,
          "tokenModifiers" => TOKEN_MODIFIERS
        }
      end

      # Get semantic tokens for entire document
      # @param uri [String] document URI
      # @return [Hash] LSP SemanticTokens
      def full(uri)
        content = @documents.get_content(uri)
        return { "data" => [] } unless content

        tokens = tokenize(content)
        { "data" => encode_tokens(tokens) }
      end

      private

      def tokenize(content)
        tokens = []
        lines = content.split("\n")

        current_section = nil
        brace_depth = 0

        lines.each_with_index do |line, line_num|
          # Comments
          if line =~ /^\s*(#.*)$/
            comment = $1
            col = line.index('#')
            tokens << [line_num, col, comment.length, 8, 0]  # comment
            next
          end

          # Section keywords
          if line =~ /\b(input|filter|output)\b/
            keyword = $1
            col = line.index(keyword)
            tokens << [line_num, col, keyword.length, 0, 1]  # namespace + definition
            current_section = keyword.to_sym
            brace_depth = 0
          end

          # Track brace depth
          brace_depth += line.count('{')
          brace_depth -= line.count('}')

          # Plugin names (at depth 1 in a section)
          if current_section && line =~ /^\s*([a-z][a-z0-9_-]*)\s*\{/i
            plugin = $1
            unless %w[input filter output if else].include?(plugin)
              col = line.index(plugin)
              tokens << [line_num, col, plugin.length, 1, 1]  # class + definition
            end
          end

          # Conditionals
          line.scan(/\b(if|else|else\s+if|and|or|xor|nand|not|in)\b/) do
            keyword = $&
            col = $~.begin(0)
            tokens << [line_num, col, keyword.length, 5, 0]  # keyword
          end

          # Option names (before =>)
          if line =~ /^\s*([a-z][a-z0-9_-]*)\s*=>/i
            option = $1
            col = line.index(option)
            tokens << [line_num, col, option.length, 2, 0]  # property
          end

          # Operators
          line.scan(/=>|==|!=|<=|>=|=~|!~|<|>/) do
            op = $&
            col = $~.begin(0)
            tokens << [line_num, col, op.length, 6, 0]  # operator
          end

          # Field references [field]
          line.scan(/\[[^\]]+\]/) do
            field = $&
            col = $~.begin(0)
            tokens << [line_num, col, field.length, 7, 0]  # variable
          end

          # Strings
          line.scan(/"[^"]*"|'[^']*'/) do
            str = $&
            col = $~.begin(0)
            tokens << [line_num, col, str.length, 3, 0]  # string
          end

          # Numbers
          line.scan(/\b-?\d+(\.\d+)?\b/) do
            num = $&
            col = $~.begin(0)
            tokens << [line_num, col, num.length, 4, 0]  # number
          end

          # Regular expressions /pattern/
          line.scan(/\/[^\/]+\//) do
            regex = $&
            col = $~.begin(0)
            tokens << [line_num, col, regex.length, 9, 0]  # regexp
          end
        end

        # Sort tokens by position (required for encoding)
        tokens.sort_by { |t| [t[0], t[1]] }
      end

      def encode_tokens(tokens)
        # LSP semantic tokens are delta-encoded
        # Each token is: [deltaLine, deltaStart, length, tokenType, tokenModifiers]
        encoded = []
        prev_line = 0
        prev_start = 0

        tokens.each do |token|
          line, start, length, type, modifiers = token

          delta_line = line - prev_line
          delta_start = delta_line == 0 ? start - prev_start : start

          encoded.push(delta_line, delta_start, length, type, modifiers)

          prev_line = line
          prev_start = start
        end

        encoded
      end
    end
  end
end
