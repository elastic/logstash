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
    # Provides folding ranges for Logstash config files
    class FoldingRangeProvider
      # Folding range kinds
      KIND_COMMENT = "comment"
      KIND_IMPORTS = "imports"
      KIND_REGION = "region"

      def initialize(document_manager)
        @documents = document_manager
      end

      # Get folding ranges
      # @param uri [String] document URI
      # @return [Array<Hash>] LSP FoldingRange array
      def folding_ranges(uri)
        content = @documents.get_content(uri)
        return [] unless content

        ranges = []
        lines = content.split("\n")

        # Track brace-based folding
        brace_stack = []  # [{line: N, char: M}, ...]

        # Track comment blocks
        comment_start = nil

        lines.each_with_index do |line, line_num|
          # Handle comment blocks
          if line =~ /^\s*#/
            comment_start ||= line_num
          else
            if comment_start && line_num - comment_start > 1
              ranges << {
                "startLine" => comment_start,
                "endLine" => line_num - 1,
                "kind" => KIND_COMMENT
              }
            end
            comment_start = nil
          end

          # Handle braces
          line.each_char.with_index do |char, col|
            if char == '{'
              brace_stack.push({ line: line_num, char: col })
            elsif char == '}' && !brace_stack.empty?
              start_pos = brace_stack.pop
              if line_num > start_pos[:line]
                ranges << {
                  "startLine" => start_pos[:line],
                  "endLine" => line_num,
                  "kind" => KIND_REGION
                }
              end
            end
          end
        end

        # Handle trailing comment block
        if comment_start && lines.length - comment_start > 1
          ranges << {
            "startLine" => comment_start,
            "endLine" => lines.length - 1,
            "kind" => KIND_COMMENT
          }
        end

        ranges
      end
    end
  end
end
