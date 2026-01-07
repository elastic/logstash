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
    # Provides diagnostics (errors, warnings) for Logstash config files
    class DiagnosticsProvider
      # LSP Diagnostic Severity
      SEVERITY_ERROR = 1
      SEVERITY_WARNING = 2
      SEVERITY_INFORMATION = 3
      SEVERITY_HINT = 4

      # Diagnostic tags
      TAG_UNNECESSARY = 1
      TAG_DEPRECATED = 2

      def initialize(schema_provider, document_manager)
        @schema = schema_provider
        @documents = document_manager
      end

      # Get diagnostics for a document
      # @param uri [String] document URI
      # @return [Hash] LSP DocumentDiagnosticReport
      def diagnose(uri)
        content = @documents.get_content(uri)
        return empty_report unless content

        diagnostics = []

        # Try to parse the config
        parse_result = parse_config(content)

        if parse_result[:error]
          diagnostics << parse_result[:error]
        else
          # Config parsed successfully, do semantic validation
          diagnostics.concat(validate_semantics(content, parse_result[:ast]))
        end

        {
          "kind" => "full",
          "items" => diagnostics
        }
      end

      private

      def empty_report
        { "kind" => "full", "items" => [] }
      end

      def parse_config(content)
        # Empty content is valid (no errors)
        return { error: nil, ast: nil } if content.nil? || content.strip.empty?

        # First check for common syntax errors that give better messages
        precheck_error = precheck_syntax(content)
        return { error: precheck_error, ast: nil } if precheck_error

        begin
          # Try to load the LSCL grammar (preferred)
          require "logstash/compiler/lscl/lscl_grammar"
          parser = LogStashCompilerLSCLGrammarParser.new
          result = parser.parse(content)

          if result.nil?
            # Parse failed
            error = create_parse_error(parser, content)
            { error: error, ast: nil }
          else
            { error: nil, ast: result }
          end
        rescue LoadError
          # LSCL grammar not available, try legacy config parser
          begin
            require "logstash/config/grammar"
            parser = LogStashConfigParser.new
            result = parser.parse(content)

            if result.nil?
              error = create_parse_error(parser, content)
              { error: error, ast: nil }
            else
              { error: nil, ast: result }
            end
          rescue LoadError
            # Parser not available (in test environment)
            # Fall back to simple validation
            { error: nil, ast: nil }
          end
        rescue => e
          # Unexpected error
          {
            error: {
              "range" => range(0, 0, 0, 0),
              "severity" => SEVERITY_ERROR,
              "source" => "logstash-lsp",
              "message" => "Parse error: #{e.message}"
            },
            ast: nil
          }
        end
      end

      def create_parse_error(parser, content)
        # Extract error information from the parser
        failure_reason = parser.failure_reason rescue "Syntax error"
        failure_line = parser.failure_line rescue 1
        failure_column = parser.failure_column rescue 1

        # Adjust to 0-based indexing
        line = [failure_line - 1, 0].max
        column = [failure_column - 1, 0].max

        # Get the line content for end position
        lines = content.split("\n", -1)
        line_length = lines[line]&.length || 0

        {
          "range" => range(line, column, line, line_length),
          "severity" => SEVERITY_ERROR,
          "source" => "logstash-lsp",
          "message" => clean_error_message(failure_reason)
        }
      end

      def clean_error_message(message)
        # Clean up Treetop's verbose error messages
        msg = message.to_s
        # Remove everything after "after line X, column Y"
        msg = msg.sub(/after line \d+, column \d+.*$/m, '').strip
        # Remove expected patterns (too verbose)
        msg = msg.sub(/Expected.*$/m, '').strip
        # Remove parenthetical content
        msg = msg.gsub(/\([^)]*\)/, '').strip
        # If we stripped everything, use generic message
        msg = "Syntax error" if msg.empty?
        msg
      end

      def precheck_syntax(content)
        lines = content.split("\n")

        # Check for unclosed strings
        unclosed_string = find_unclosed_string(lines)
        return unclosed_string if unclosed_string

        # Check for unbalanced braces
        unbalanced = find_unbalanced_braces(lines)
        return unbalanced if unbalanced

        # Check for unbalanced brackets
        unbalanced = find_unbalanced_brackets(lines)
        return unbalanced if unbalanced

        nil
      end

      def find_unclosed_string(lines)
        lines.each_with_index do |line, line_num|
          # Skip comment lines
          next if line.strip.start_with?('#')

          in_double_quote = false
          in_single_quote = false
          quote_start_col = nil
          i = 0

          while i < line.length
            char = line[i]
            prev_char = i > 0 ? line[i - 1] : nil

            # Skip escaped characters
            if prev_char == '\\'
              i += 1
              next
            end

            if char == '"' && !in_single_quote
              if in_double_quote
                in_double_quote = false
              else
                in_double_quote = true
                quote_start_col = i
              end
            elsif char == "'" && !in_double_quote
              if in_single_quote
                in_single_quote = false
              else
                in_single_quote = true
                quote_start_col = i
              end
            end

            i += 1
          end

          if in_double_quote || in_single_quote
            quote_type = in_double_quote ? 'double' : 'single'
            return {
              "range" => range(line_num, quote_start_col, line_num, line.length),
              "severity" => SEVERITY_ERROR,
              "source" => "logstash-lsp",
              "message" => "Unclosed #{quote_type}-quoted string"
            }
          end
        end

        nil
      end

      def find_unbalanced_braces(lines)
        brace_stack = []  # [{line, col}, ...]

        lines.each_with_index do |line, line_num|
          next if line.strip.start_with?('#')

          in_string = false
          quote_char = nil
          i = 0

          while i < line.length
            char = line[i]
            prev_char = i > 0 ? line[i - 1] : nil

            # Skip escaped characters
            if prev_char == '\\'
              i += 1
              next
            end

            # Track string state
            if (char == '"' || char == "'") && prev_char != '\\'
              if in_string && char == quote_char
                in_string = false
                quote_char = nil
              elsif !in_string
                in_string = true
                quote_char = char
              end
            elsif !in_string
              if char == '{'
                brace_stack.push({ line: line_num, col: i })
              elsif char == '}'
                if brace_stack.empty?
                  return {
                    "range" => range(line_num, i, line_num, i + 1),
                    "severity" => SEVERITY_ERROR,
                    "source" => "logstash-lsp",
                    "message" => "Unexpected closing brace '}'"
                  }
                end
                brace_stack.pop
              end
            end

            i += 1
          end
        end

        unless brace_stack.empty?
          unclosed = brace_stack.last
          return {
            "range" => range(unclosed[:line], unclosed[:col], unclosed[:line], unclosed[:col] + 1),
            "severity" => SEVERITY_ERROR,
            "source" => "logstash-lsp",
            "message" => "Unclosed brace '{'"
          }
        end

        nil
      end

      def find_unbalanced_brackets(lines)
        bracket_stack = []

        lines.each_with_index do |line, line_num|
          next if line.strip.start_with?('#')

          in_string = false
          quote_char = nil
          i = 0

          while i < line.length
            char = line[i]
            prev_char = i > 0 ? line[i - 1] : nil

            if prev_char == '\\'
              i += 1
              next
            end

            if (char == '"' || char == "'") && prev_char != '\\'
              if in_string && char == quote_char
                in_string = false
                quote_char = nil
              elsif !in_string
                in_string = true
                quote_char = char
              end
            elsif !in_string
              if char == '['
                bracket_stack.push({ line: line_num, col: i })
              elsif char == ']'
                if bracket_stack.empty?
                  return {
                    "range" => range(line_num, i, line_num, i + 1),
                    "severity" => SEVERITY_ERROR,
                    "source" => "logstash-lsp",
                    "message" => "Unexpected closing bracket ']'"
                  }
                end
                bracket_stack.pop
              end
            end

            i += 1
          end
        end

        unless bracket_stack.empty?
          unclosed = bracket_stack.last
          return {
            "range" => range(unclosed[:line], unclosed[:col], unclosed[:line], unclosed[:col] + 1),
            "severity" => SEVERITY_ERROR,
            "source" => "logstash-lsp",
            "message" => "Unclosed bracket '['"
          }
        end

        nil
      end

      def validate_semantics(content, ast)
        diagnostics = []

        # Simple regex-based validation when AST is not available
        # This provides basic validation without requiring the full parser

        # Find all plugin blocks and validate them
        diagnostics.concat(validate_plugins(content))

        # Check for deprecated options
        diagnostics.concat(check_deprecated_options(content))

        # Check for unknown plugins
        diagnostics.concat(check_unknown_plugins(content))

        diagnostics
      end

      def validate_plugins(content)
        diagnostics = []
        lines = content.split("\n")

        current_section = nil
        current_plugin = nil
        plugin_start_line = nil
        plugin_start_column = nil
        brace_depth = 0
        plugin_options = []

        lines.each_with_index do |line, line_num|
          # Track section
          if line =~ /^\s*(input|filter|output)\s*\{/
            current_section = $1.to_sym
            brace_depth = 1
          elsif current_section
            # Check for plugins and options BEFORE updating brace depth
            if brace_depth == 1 && line =~ /^\s*([a-z][a-z0-9_-]*)\s*\{/i
              # At section level, look for plugins
              # Validate previous plugin if any
              if current_plugin && plugin_start_line
                diags = validate_plugin_config(current_section, current_plugin, plugin_options, plugin_start_line, plugin_start_column)
                diagnostics.concat(diags)
              end

              current_plugin = $1
              plugin_start_line = line_num
              plugin_start_column = line.index($1)
              plugin_options = []
            elsif brace_depth == 2 && current_plugin
              # Inside plugin, collect option names
              if line =~ /^\s*([a-z][a-z0-9_-]*)\s*=>/i
                plugin_options << { name: $1, line: line_num, column: line.index($1) }
              end
            end

            # Track brace depth after checking
            brace_depth += line.count('{')
            brace_depth -= line.count('}')

            if brace_depth == 0
              # Validate last plugin before leaving section
              if current_plugin && plugin_start_line
                diags = validate_plugin_config(current_section, current_plugin, plugin_options, plugin_start_line, plugin_start_column)
                diagnostics.concat(diags)
              end
              current_section = nil
              current_plugin = nil
              plugin_options = []
            end
          end
        end

        # Validate last plugin if any (if file ends without closing section)
        if current_plugin && plugin_start_line && current_section
          diags = validate_plugin_config(current_section, current_plugin, plugin_options, plugin_start_line, plugin_start_column)
          diagnostics.concat(diags)
        end

        diagnostics
      end

      def validate_plugin_config(section, plugin_name, options, plugin_line, plugin_column)
        diagnostics = []

        return diagnostics unless @schema.plugin_exists?(section, plugin_name)

        schema_options = @schema.plugin_options(section, plugin_name)
        option_names = options.map { |o| o[:name] }

        # Check for unknown options
        options.each do |opt|
          unless schema_options.key?(opt[:name])
            diagnostics << {
              "range" => range(opt[:line], opt[:column], opt[:line], opt[:column] + opt[:name].length),
              "severity" => SEVERITY_WARNING,
              "source" => "logstash-lsp",
              "message" => "Unknown option '#{opt[:name]}' for #{plugin_name}"
            }
          end
        end

        # Check for missing required options
        schema_options.each do |name, details|
          if details[:required] && !option_names.include?(name)
            diagnostics << {
              "range" => range(plugin_line, plugin_column, plugin_line, plugin_column + plugin_name.length),
              "severity" => SEVERITY_ERROR,
              "source" => "logstash-lsp",
              "message" => "Missing required option '#{name}' for #{plugin_name}"
            }
          end
        end

        # Check for deprecated options
        options.each do |opt|
          if schema_options[opt[:name]]&.dig(:deprecated)
            diagnostics << {
              "range" => range(opt[:line], opt[:column], opt[:line], opt[:column] + opt[:name].length),
              "severity" => SEVERITY_WARNING,
              "source" => "logstash-lsp",
              "tags" => [TAG_DEPRECATED],
              "message" => "Option '#{opt[:name]}' is deprecated"
            }
          end
        end

        diagnostics
      end

      def check_deprecated_options(content)
        # Additional deprecated option checks handled in validate_plugin_config
        []
      end

      def check_unknown_plugins(content)
        diagnostics = []
        lines = content.split("\n")

        current_section = nil
        section_brace_depth = 0

        lines.each_with_index do |line, line_num|
          # Track section
          if line =~ /^\s*(input|filter|output)\s*\{/
            current_section = $1.to_sym
            section_brace_depth = 1

            # Check for plugins on the same line as section (e.g., "input { stdin {} }")
            # Get the part after "section {"
            after_section = line.sub(/^\s*(input|filter|output)\s*\{/, '')
            check_plugins_in_text(after_section, line_num, line, current_section, diagnostics)
          elsif current_section
            # Check for plugins BEFORE updating brace depth
            # At section level (depth 1), look for plugin names
            if section_brace_depth == 1 && line =~ /^\s*([a-z][a-z0-9_-]*)\s*\{/i
              plugin_name = $1
              column = line.index(plugin_name)

              unless @schema.plugin_exists?(current_section, plugin_name)
                # Check for similar plugin names
                suggestion = find_similar_plugin(current_section, plugin_name)
                message = "Unknown #{current_section} plugin '#{plugin_name}'"
                message += ". Did you mean '#{suggestion}'?" if suggestion

                diagnostics << {
                  "range" => range(line_num, column, line_num, column + plugin_name.length),
                  "severity" => SEVERITY_ERROR,
                  "source" => "logstash-lsp",
                  "message" => message
                }
              end
            end

            # Update brace depth after checking
            section_brace_depth += line.count('{')
            section_brace_depth -= line.count('}')

            if section_brace_depth == 0
              current_section = nil
            end
          end
        end

        diagnostics
      end

      def check_plugins_in_text(text, line_num, full_line, section, diagnostics)
        # Find all plugin patterns in the text
        text.scan(/([a-z][a-z0-9_-]*)\s*\{/i) do |match|
          plugin_name = match[0]
          next if plugin_name.nil?

          # Find the actual column in the full line
          column = full_line.index(plugin_name)
          next unless column

          unless @schema.plugin_exists?(section, plugin_name)
            suggestion = find_similar_plugin(section, plugin_name)
            message = "Unknown #{section} plugin '#{plugin_name}'"
            message += ". Did you mean '#{suggestion}'?" if suggestion

            diagnostics << {
              "range" => range(line_num, column, line_num, column + plugin_name.length),
              "severity" => SEVERITY_ERROR,
              "source" => "logstash-lsp",
              "message" => message
            }
          end
        end
      end

      def find_similar_plugin(section, name)
        plugins = @schema.plugin_names(section)
        return nil if plugins.empty?

        # Simple Levenshtein-like similarity
        best_match = nil
        best_score = Float::INFINITY

        plugins.each do |plugin|
          score = levenshtein_distance(name.downcase, plugin.downcase)
          if score < best_score && score <= 3  # Max 3 edits
            best_score = score
            best_match = plugin
          end
        end

        best_match
      end

      def levenshtein_distance(s1, s2)
        m = s1.length
        n = s2.length

        return n if m == 0
        return m if n == 0

        d = Array.new(m + 1) { Array.new(n + 1) }

        (0..m).each { |i| d[i][0] = i }
        (0..n).each { |j| d[0][j] = j }

        (1..m).each do |i|
          (1..n).each do |j|
            cost = s1[i - 1] == s2[j - 1] ? 0 : 1
            d[i][j] = [
              d[i - 1][j] + 1,      # deletion
              d[i][j - 1] + 1,      # insertion
              d[i - 1][j - 1] + cost # substitution
            ].min
          end
        end

        d[m][n]
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
