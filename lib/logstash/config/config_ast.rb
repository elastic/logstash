# encoding: utf-8
require "treetop"
class Treetop::Runtime::SyntaxNode
  def compile
    return "" if elements.nil?
    return elements.collect(&:compile).reject(&:empty?).join("")
  end

  def recursive_inject(results=[], &block)
    if !elements.nil?
      elements.each do |element|
        if block.call(element)
          results << element
        else
          element.recursive_inject(results, &block)
        end
      end
    end
    return results
  end

  def recursive_select(klass)
    return recursive_inject { |e| e.is_a?(klass) }
  end

  def recursive_inject_parent(results=[], &block)
    if !parent.nil?
      if block.call(parent)
        results << parent
      else
        parent.recursive_inject_parent(results, &block)
      end
    end
    return results
  end

  def recursive_select_parent(results=[], klass)
    return recursive_inject_parent(results) { |e| e.is_a?(klass) }
  end
end

module LogStash; module Config; module AST 
  class Node < Treetop::Runtime::SyntaxNode; end
  class Config < Node
    def compile
      # TODO(sissel): Move this into config/config_ast.rb
      code = []
      code << "@inputs = []"
      code << "@filters = []"
      code << "@outputs = []"
      sections = recursive_select(LogStash::Config::AST::PluginSection)
      sections.each do |s|
        code << s.compile_initializer
      end

      # start inputs
      #code << "class << self"
      definitions = []
        
      ["filter", "output"].each do |type|
        #definitions << "def #{type}(event)"
        definitions << "@#{type}_func = lambda do |event, &block|"
        if type == "filter"
          definitions << "  extra_events = []"
        end

        definitions << "  @logger.debug? && @logger.debug(\"#{type} received\", :event => event.to_hash)"
        sections.select { |s| s.plugin_type.text_value == type }.each do |s|
          definitions << s.compile.split("\n", -1).map { |e| "  #{e}" }
        end

        if type == "filter"
          definitions << "  extra_events.each(&block)"
        end
        definitions << "end"
      end

      code += definitions.join("\n").split("\n", -1).collect { |l| "  #{l}" }
      #code << "end"
      return code.join("\n")
    end
  end

  class Comment < Node; end
  class Whitespace < Node; end
  class PluginSection < Node
    @@i = 0
    # Generate ruby code to initialize all the plugins.
    def compile_initializer
      generate_variables
      code = []
      @variables.collect do |plugin, name|
        code << "#{name} = #{plugin.compile_initializer}"
        code << "@#{plugin.plugin_type}s << #{name}"
      end
      return code.join("\n")
    end

    def variable(object)
      generate_variables
      return @variables[object]
    end

    def generate_variables
      return if !@variables.nil?
      @variables = {}
      plugins = recursive_select(Plugin)

      plugins.each do |plugin|
        # Unique number for every plugin.
        @@i += 1
        # store things as ivars, like @filter_grok_3
        var = "@#{plugin.plugin_type}_#{plugin.plugin_name}_#{@@i}"
        @variables[plugin] = var
      end
      return @variables
    end

  end

  class Plugins < Node; end
  class Plugin < Node
    def plugin_type
      if recursive_select_parent(Plugin).any?
        return "codec"
      else
        return recursive_select_parent(PluginSection).first.plugin_type.text_value
      end
    end

    def plugin_name
      return name.text_value
    end

    def variable_name
      return recursive_select_parent(PluginSection).first.variable(self)
    end

    def compile_initializer
      # If any parent is a Plugin, this must be a codec.

      if attributes.elements.nil?
        return "plugin(#{plugin_type.inspect}, #{plugin_name.inspect})" << (plugin_type == "codec" ? "" : "\n")
      else
        settings = attributes.recursive_select(Attribute).collect(&:compile).reject(&:empty?)

        attributes_code = "LogStash::Util.hash_merge_many(#{settings.map { |c| "{ #{c} }" }.join(", ")})"
        return "plugin(#{plugin_type.inspect}, #{plugin_name.inspect}, #{attributes_code})" << (plugin_type == "codec" ? "" : "\n")
      end
    end

    def compile
      case plugin_type
        when "input"
          return "start_input(#{variable_name})"
        when "filter"
          # This is some pretty stupid code, honestly.
          # I'd prefer much if it were put into the Pipeline itself
          # and this should simply compile to 
          #   #{variable_name}.filter(event)
          return [
            "newevents = []",
            "extra_events.each do |event|",
            "  #{variable_name}.filter(event) do |newevent|",
            "    newevents << newevent",
            "  end",
            "end",
            "extra_events += newevents",

            "#{variable_name}.filter(event) do |newevent|",
            "  extra_events << newevent",
            "end",
            "if event.cancelled?",
            "  extra_events.each(&block)",
            "  return",
            "end",
          ].map { |l| "#{l}\n" }.join("")
        when "output"
          return "#{variable_name}.handle(event)\n"
        when "codec"
          settings = attributes.recursive_select(Attribute).collect(&:compile).reject(&:empty?)
          attributes_code = "LogStash::Util.hash_merge_many(#{settings.map { |c| "{ #{c} }" }.join(", ")})"
          return "plugin(#{plugin_type.inspect}, #{plugin_name.inspect}, #{attributes_code})"
      end
    end
  end

  class Name < Node
    def compile
      return text_value.inspect
    end
  end
  class Attribute < Node
    def compile
      return %Q(#{name.compile} => #{value.compile})
    end
  end
  class RValue < Node; end
  class Value < RValue; end

  module Unicode
    def self.wrap(text)
      return "(" + text.inspect + ".force_encoding(\"UTF-8\")" + ")"
    end
  end

  class Bareword < Value
    def compile
      return Unicode.wrap(text_value)
    end
  end
  class String < Value
    def compile
      return Unicode.wrap(text_value[1...-1])
    end
  end
  class RegExp < Value
    def compile
      return "Regexp.new(" + Unicode.wrap(text_value[1...-1]) + ")"
    end
  end
  class Number < Value
    def compile
      return text_value
    end
  end
  class Array < Value
    def compile
      return "[" << recursive_select(Value).collect(&:compile).reject(&:empty?).join(", ") << "]"
    end
  end
  class Hash < Value
    def compile
      return "{" << recursive_select(HashEntry).collect(&:compile).reject(&:empty?).join(", ") << "}"
    end
  end
  class HashEntries < Node; end
  class HashEntry < Node
    def compile
      return %Q(#{name.compile} => #{value.compile})
    end
  end

  class BranchOrPlugin < Node; end

  class Branch < Node
    def compile
      return super + "end\n"
    end
  end
  class If < Node
    def compile
      children = recursive_inject { |e| e.is_a?(Branch) || e.is_a?(Plugin) }
      return "if #{condition.compile}\n" \
        << children.collect(&:compile).map { |s| s.split("\n", -1).map { |l| "  " + l }.join("\n") }.join("") << "\n"
    end
  end
  class Elsif < Node
    def compile
      children = recursive_inject { |e| e.is_a?(Branch) || e.is_a?(Plugin) }
      return "elsif #{condition.compile}\n" \
        << children.collect(&:compile).map { |s| s.split("\n", -1).map { |l| "  " + l }.join("\n") }.join("") << "\n"
    end
  end
  class Else < Node
    def compile
      children = recursive_inject { |e| e.is_a?(Branch) || e.is_a?(Plugin) }
      return "else\n" \
        << children.collect(&:compile).map { |s| s.split("\n", -1).map { |l| "  " + l }.join("\n") }.join("") << "\n"
    end
  end

  class Condition < Node
    def compile
      return "(#{super})"
    end
  end

  module Expression
    def compile
      return "(#{super})"
    end
  end

  module NegativeExpression
    def compile
      return "!(#{super})"
    end
  end

  module ComparisonExpression; end

  module InExpression
    def compile
      item, list = recursive_select(LogStash::Config::AST::RValue)
      return "(x = #{list.compile}; x.respond_to?(:include?) && x.include?(#{item.compile}))"
    end
  end

  module NotInExpression
    def compile
      item, list = recursive_select(LogStash::Config::AST::RValue)
      return "(x = #{list.compile}; !x.respond_to?(:include?) || !x.include?(#{item.compile}))"
    end
  end

  class MethodCall < Node
    def compile
      arguments = recursive_inject { |e| [String, Number, Selector, Array, MethodCall].any? { |c| e.is_a?(c) } }
      return "#{method.text_value}(" << arguments.collect(&:compile).join(", ") << ")"
    end
  end

  class RegexpExpression < Node
    def compile
      operator = recursive_select(LogStash::Config::AST::RegExpOperator).first.text_value
      item, regexp = recursive_select(LogStash::Config::AST::RValue)
      # Compile strings to regexp's
      if regexp.is_a?(LogStash::Config::AST::String)
        regexp = "/#{regexp.text_value[1..-2]}/"
      else
        regexp = regexp.compile
      end
      return "(#{item.compile} #{operator} #{regexp})"
    end
  end

  module ComparisonOperator 
    def compile
      return " #{text_value} "
    end
  end
  module RegExpOperator
    def compile
      return " #{text_value} "
    end
  end
  module BooleanOperator
    def compile
      return " #{text_value} "
    end
  end
  class Selector < RValue
    def compile
      return "event[#{text_value.inspect}]"
    end
  end
  class SelectorElement < Node; end
end; end; end


# Monkeypatch Treetop::Runtime::SyntaxNode's inspect method to skip
# any Whitespace or SyntaxNodes with no children.
class Treetop::Runtime::SyntaxNode
  def _inspect(indent="")
    em = extension_modules
    interesting_methods = methods-[em.last ? em.last.methods : nil]-self.class.instance_methods
    im = interesting_methods.size > 0 ? " (#{interesting_methods.join(",")})" : ""
    tv = text_value
    tv = "...#{tv[-20..-1]}" if tv.size > 20

    indent +
    self.class.to_s.sub(/.*:/,'') +
      em.map{|m| "+"+m.to_s.sub(/.*:/,'')}*"" +
      " offset=#{interval.first}" +
      ", #{tv.inspect}" +
      im +
      (elements && elements.size > 0 ?
        ":" +
          (elements.select { |e| !e.is_a?(LogStash::Config::AST::Whitespace) && e.elements && e.elements.size > 0 }||[]).map{|e|
      begin
        "\n"+e.inspect(indent+"  ")
      rescue  # Defend against inspect not taking a parameter
        "\n"+indent+" "+e.inspect
      end
          }.join("") :
        ""
      )
  end
end
