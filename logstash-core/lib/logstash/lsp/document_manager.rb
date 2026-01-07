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
    # Manages open documents and provides position/context utilities for LSP
    class DocumentManager
      # Context types returned by get_context_at
      CONTEXT_TYPES = [
        :root,           # At root level, outside any section
        :section,        # Inside a section (input/filter/output) but outside plugin
        :plugin_name,    # Where a plugin name should go
        :plugin_block,   # Inside a plugin block
        :attribute_name, # Where an attribute name should go
        :attribute_value # After => where a value should go
      ].freeze

      def initialize
        @documents = {}
        @mutex = Mutex.new
      end

      # Open a document for tracking
      def open(uri, content, version = 1)
        @mutex.synchronize do
          @documents[uri] = {
            content: content,
            version: version,
            lines: nil  # Lazily computed
          }
        end
      end

      # Update document content
      def update(uri, content, version)
        @mutex.synchronize do
          if @documents[uri]
            @documents[uri][:content] = content
            @documents[uri][:version] = version
            @documents[uri][:lines] = nil  # Invalidate line cache
          else
            open(uri, content, version)
          end
        end
      end

      # Close a document
      def close(uri)
        @mutex.synchronize do
          @documents.delete(uri)
        end
      end

      # Get document content
      def get_content(uri)
        @documents.dig(uri, :content)
      end

      # Get document version
      def get_version(uri)
        @documents.dig(uri, :version)
      end

      # Check if document is open
      def open?(uri)
        @documents.key?(uri)
      end

      # Convert line/character position to byte offset
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @return [Integer, nil] byte offset or nil if invalid
      def position_to_offset(uri, line, character)
        content = get_content(uri)
        return nil unless content

        lines = get_lines(uri)
        return nil if line < 0 || line >= lines.length

        offset = 0
        lines.each_with_index do |line_content, idx|
          if idx == line
            char_offset = [character, line_content.length].min
            return offset + char_offset
          end
          offset += line_content.length + 1  # +1 for newline
        end

        nil
      end

      # Convert byte offset to line/character position
      # @param uri [String] document URI
      # @param offset [Integer] byte offset
      # @return [Hash, nil] { line:, character: } or nil if invalid
      def offset_to_position(uri, offset)
        content = get_content(uri)
        return nil unless content
        return nil if offset < 0 || offset > content.length

        current_offset = 0
        lines = get_lines(uri)

        lines.each_with_index do |line_content, line_num|
          line_end = current_offset + line_content.length

          if offset <= line_end
            return { line: line_num, character: offset - current_offset }
          end

          current_offset = line_end + 1  # +1 for newline
        end

        # At end of document
        { line: lines.length - 1, character: lines.last&.length || 0 }
      end

      # Get the word at a position (for hover/completion context)
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @return [Hash, nil] { word:, start:, end: } or nil
      def get_word_at(uri, line, character)
        content = get_content(uri)
        return nil unless content

        lines = get_lines(uri)
        return nil if line < 0 || line >= lines.length

        line_content = lines[line]
        return nil if character < 0 || character > line_content.length

        # Find word boundaries (alphanumeric, underscore, hyphen)
        word_chars = /[A-Za-z0-9_-]/

        # Find start of word
        start_pos = character
        while start_pos > 0 && line_content[start_pos - 1] =~ word_chars
          start_pos -= 1
        end

        # Find end of word
        end_pos = character
        while end_pos < line_content.length && line_content[end_pos] =~ word_chars
          end_pos += 1
        end

        return nil if start_pos == end_pos

        {
          word: line_content[start_pos...end_pos],
          start: start_pos,
          end: end_pos
        }
      end

      # Get context at a position for completion/hover
      # @param uri [String] document URI
      # @param line [Integer] 0-based line number
      # @param character [Integer] 0-based character offset
      # @return [Hash] context information
      def get_context_at(uri, line, character)
        content = get_content(uri)
        return { type: :root } unless content

        offset = position_to_offset(uri, line, character)
        return { type: :root } unless offset

        # Get text up to cursor position for analysis
        text_before = content[0...offset]

        # Analyze the context using simple pattern matching
        # This is a simplified approach; a full implementation would use the AST
        analyze_context(text_before, content, offset)
      end

      private

      def get_lines(uri)
        doc = @documents[uri]
        return [] unless doc

        doc[:lines] ||= doc[:content].split("\n", -1)
        doc[:lines]
      end

      def analyze_context(text_before, full_content, offset)
        # Count open braces to determine nesting level
        brace_depth = count_braces(text_before)

        # Check if we're in a section
        section_match = text_before.scan(/\b(input|filter|output)\s*\{/).last
        section_type = section_match&.first&.to_sym

        # Section keywords to exclude from plugin matching
        section_keywords = %w[input filter output]

        # Check for most recent plugin (excluding section keywords)
        # Look for pattern: word { ... } where we're inside the braces
        plugin_pattern = /\b([a-z][a-z0-9_-]*)\s*\{/i
        all_matches = text_before.scan(plugin_pattern).flatten
        plugins = all_matches.reject { |name| section_keywords.include?(name.downcase) }

        # Check if we're after =>
        after_arrow = text_before =~ /=>\s*$/

        # Check if we're in a plugin block (by counting braces after plugin name)
        in_plugin_block = false
        current_plugin = nil

        if section_type && plugins.any?
          # Find the last plugin that we're inside (not a section keyword)
          plugins.reverse_each do |plugin_name|
            pattern = /\b#{Regexp.escape(plugin_name)}\s*\{/i
            match_pos = text_before.rindex(pattern)
            if match_pos
              text_after_plugin = text_before[match_pos..-1]
              plugin_braces = count_braces(text_after_plugin)
              if plugin_braces > 0
                in_plugin_block = true
                current_plugin = plugin_name
                break
              end
            end
          end
        end

        # Determine context type
        context = {
          type: determine_context_type(brace_depth, section_type, in_plugin_block, after_arrow, text_before),
          section: section_type,
          plugin: current_plugin,
          brace_depth: brace_depth
        }

        # Add word at cursor if relevant
        word_info = extract_word_at_cursor(text_before)
        context[:current_word] = word_info[:word] if word_info
        context[:word_start] = word_info[:start] if word_info

        # Add current line text for value completion
        lines = full_content.split("\n", -1)
        line_index = text_before.count("\n")
        context[:line_text] = lines[line_index] if line_index < lines.length

        context
      end

      def determine_context_type(brace_depth, section_type, in_plugin_block, after_arrow, text_before)
        return :root if brace_depth == 0

        if after_arrow
          return :attribute_value
        end

        if in_plugin_block
          # Check if we're at a position where an attribute name is expected
          # (after newline or at start of plugin block)
          if text_before =~ /\{\s*$/ || text_before =~ /\n\s*$/
            return :attribute_name
          end
          return :plugin_block
        end

        if section_type && brace_depth == 1
          # Inside section but not in a plugin
          return :plugin_name
        end

        if brace_depth >= 1 && section_type
          return :section
        end

        :root
      end

      def count_braces(text)
        # Count braces but skip those inside strings
        depth = 0
        in_string = false
        quote_char = nil
        i = 0

        while i < text.length
          char = text[i]
          prev_char = i > 0 ? text[i - 1] : nil

          # Skip escaped characters
          if prev_char == '\\'
            i += 1
            next
          end

          # Track string state
          if (char == '"' || char == "'") && !in_string
            in_string = true
            quote_char = char
          elsif in_string && char == quote_char
            in_string = false
            quote_char = nil
          elsif !in_string
            depth += 1 if char == '{'
            depth -= 1 if char == '}'
          end

          i += 1
        end

        depth
      end

      def extract_word_at_cursor(text)
        # Extract the word being typed at the absolute end of the text
        # Use \z instead of $ to match only the true end (not end of line)
        match = text.match(/([A-Za-z0-9_-]+)\z/)
        return nil unless match

        {
          word: match[1],
          start: text.length - match[1].length
        }
      end
    end
  end
end
