# encoding: utf-8
module LogStash::Docgen
  # This class is parsing static content of the main class and
  # his ancestors, the result would be the description of the plugin and the
  # actual documentation for each of the option.
  class StaticParser
    COMMENTS_IGNORE = ["encoding: utf-8"]

    VALID_CLASS_NAME = /^LogStash::(Codecs|Inputs|Filters|Outputs)::(\w+)/
    COMMENT_RE = /^ *#(?: (.*)| *$)/
    MULTILINE_RE = /(, *$)|(\\$)|(\[ *$)/
    ENDLINES_RE = /\r\n|\n/
    CLASS_DEFINITION_RE = /^ *class\s(.*) < *(::)?LogStash::(Outputs|Filters|Inputs|Codecs)::(\w)/ 
    NEW_CLASS_DEFINITION_RE = /^module (\w+) module (\w+) class\s(.*) < *(::)?LogStash::(Outputs|Filters|Inputs|Codecs)::(\w)/
    NEW_CLASS_DEFINITION_RE_ML = /module LogStash\n\s+module (Inputs|Codec|Outputs|Filters)\n.+\s+class (\w+) < *(::)?LogStash::(Inputs|Outputs|Filters|Codec)::/m
    CONFIG_OPTION_RE = /^\s*((mod|base).)?config +[^=].*/
    CONFIG_NAME_RE = /^ *config_name .*/
    RESET_DOCUMENTATION_BUFFER_RE = /^ *(class|def|module) /

    def initialize(context)
      @rules = {
        COMMENT_RE => :parse_comment,
        CLASS_DEFINITION_RE => :parse_class_description,
        NEW_CLASS_DEFINITION_RE => :parse_new_class_description,
        CONFIG_OPTION_RE => :parse_config,
        CONFIG_NAME_RE => :parse_config_name,
        RESET_DOCUMENTATION_BUFFER_RE => :update_description
      }

      @context = context

      # Extracting the class name and parsing file
      # work on the same raw content of the file, we use this cache to make sure
      # we dont waste resources on reading the content
      @cached_read = {}

      reset_buffer
    end

    def parse_class_description(class_definition)
      @context.section = class_definition[3].downcase.gsub(/s$/, '')
      @context.name = class_definition[1]

      update_description
    end

    def parse_new_class_description(class_definition)
      @context.section = class_definition[2].downcase.gsub(/s$/, '')
      @context.name = "#{class_definition[1]}::#{class_definition[2]}::#{class_definition[3]}"

      update_description
    end

    # This is not obvious, but if the plugin define a class before the main class it can trip the buffer
    def update_description(match = nil)
      description = flush_buffer

      # can only be change by the main file
      @context.description = description if !@context.has_description? && main?
    end

    def parse_config_name(match)
      if main?
        name = match[0].match(/config_name\s++["'](\w+)['"]/)[1]
        @context.config_name = name
        @context.name = name
      end
    end

    def parse_comment(match)
      comment = match[1]
      return if ignore_comment?(comment)
      @buffer << comment
    end

    def parse_config(match)
      field = match[0]
      field_name = field.match(/config\s+:(\w+)/)[1]
      @context.add_config_description(field_name, flush_buffer)
    end

    def parse(file, main = false)
      @main = main
      reset_buffer
      string = read_file(file)
      extract_lines(string).each { |line| parse_line(line) }
    end

    def main?
      @main
    end

    def parse_line(line)
      @rules.each do |re, action|
        if match = re.match(line)
          send(action, match)
        end
      end 
    end

    def extract_lines(string)
      buffer = ""
      string.split(ENDLINES_RE).collect do |line|
        # Join extended lines
        if !comment?(line) && multiline?(line)
          buffer += line.chomp
          next
        end

        line = buffer + line
        buffer = ""

        line
      end
    end

    def ignore_comment?(comment)
      COMMENTS_IGNORE.include?(comment)
    end

    def comment?(line)
      line =~ COMMENT_RE
    end

    def multiline?(line)
      line =~ MULTILINE_RE
    end

    def flush_buffer
      content = @buffer.join("\n")
      reset_buffer
      content
    end

    def reset_buffer(match = nil)
      @buffer = []
    end

    def read_file(file)
      @cached_read[file] ||= File.read(file)
    end

    # Let's try to extract a meaninful name for the classes
    # We need to support theses format:
    #
    # class LogStash::Inputs::File # legacy
    # module LogStash module inputs File
    # module LogStash
    #    ....
    #    module Inputs
    #    ...
    #    class File
    def extract_class_name(file)
      content = read_file(file)
      legacy_definition = content.match(CLASS_DEFINITION_RE)

      if legacy_definition.nil?
        match_data = content.match(NEW_CLASS_DEFINITION_RE)
        "#{match_data[1]}::#{match_data[2]}::#{match_data[3]}"
      else
        if valid_class_name(legacy_definition[1])
          legacy_definition[1]
        else
          m = content.match(NEW_CLASS_DEFINITION_RE_ML)
          "LogStash::#{m[1]}::#{m[2]}"
        end
      end
    end

    def valid_class_name(klass_name)
      klass_name =~ VALID_CLASS_NAME
    end
  end
end
