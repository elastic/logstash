require "treetop"
class Treetop::Runtime::SyntaxNode
  def generate_config
    return "" if elements.nil?
    return elements.collect(&:generate_config).reject(&:empty?).join("")
  end

  def compile
    return "" if elements.nil?
    return elements.collect(&:compile).reject(&:empty?).join("")
  end

  def recursive_select(results=[], &block)
    if !elements.nil?
      elements.each do |e|
        if block.call(e)
          results << e
        else
          e.recursive_select(results, &block)
        end
      end
    end
    return results
  end

  def recursive_select_parent(results=[], &block)
    if !parent.nil?
      if block.call(parent)
        results << parent
      else
        parent.recursive_select_parent(results, &block)
      end
    end
    return results
  end
end

module LogStash; module Config; module AST 
  class Node < Treetop::Runtime::SyntaxNode; end
  class Config < Node; end
  class Comment < Node; end
  class Whitespace < Node; end

  class PluginSection < Node
    def generate_config
      return "#{plugin_type.text_value} {\n" << super << "}\n"
    end
  end
  class Plugins < Node; end
  class Plugin < Node
    def generate_config
      return "#{name.text_value} {\n" << attributes.elements.collect(&:generate_config).join("") << "}\n"
    end

    def compile
      # Search up the stack for the PluginSection we're in
      plugin_type = recursive_select_parent { |e| e.is_a?(PluginSection) }.first.plugin_type.text_value.inspect

      # Unless we're inside a Plugin, then any 'plugin object is actually a
      # codec.
      is_codec = recursive_select_parent { |e| e.is_a?(Plugin) }.any?

      plugin_type = "codec".inspect if is_codec

      if attributes.elements.nil?
        return "plugin(#{plugin_type}, #{name.text_value.inspect})" << (is_codec ? "" : "\n")
      else
        return "plugin(#{plugin_type}, #{name.text_value.inspect}, " << attributes.recursive_select { |e| e.is_a?(Attribute) }.collect(&:compile).reject(&:empty?).join(", ") << ")" << (is_codec ? "" : "\n")
      end
    end
  end
  class Name < Node
    def generate_config
      return text_value
    end

    def compile
      return text_value.inspect
    end
  end
  class Attribute < Node
    def generate_config
      return %Q(#{name.generate_config} => #{value.generate_config}\n)
    end
    def compile
      return %Q(#{name.compile} => #{value.compile})
    end
  end
  class Value < Node; end
  class Bareword < Value
    def generate_config
      return text_value.inspect
    end
    def compile
      return text_value.inspect
    end
  end
  class String < Value
    def generate_config
      return text_value[1...-1].inspect
    end
    def compile
      return text_value[1...-1].inspect
    end
  end
  class Number < Value
    def generate_config
      return text_value
    end
    def compile
      return text_value
    end
  end
  class Array < Value
    def generate_config
      return "[" << recursive_select { |e| e.is_a?(Value) }.collect(&:generate_config).join(", ") << "]"
    end
    def compile
      return "[" << recursive_select { |e| e.is_a?(Value) }.collect(&:compile).reject(&:empty?).join(", ") << "]"
    end
  end
  class Hash < Value
    def generate_config
      return "{" << recursive_select { |e| e.is_a?(HashEntry) }.collect(&:generate_config).join(" ") << "}"
    end
    def compile
      return "{" << recursive_select { |e| e.is_a?(HashEntry) }.collect(&:compile).reject(&:empty?).join(", ") << "}"
    end
  end
  class HashEntries < Node; end
  class HashEntry < Node
    def generate_config
      return %Q(#{name.generate_config} => #{value.generate_config}\n)
    end
    def compile
      return %Q(#{name.compile} => #{value.compile})
    end
  end

  class Branch < Node; end
  class If < Node; end
  class Elsif < Node; end
  class Else < Node; end
  class Condition < Node; end
  class Expression < Node; end
  class Rvalue < Node; end
  class ComparisonOperator < Node; end
  class BooleanOperator < Node; end
  class Selector < Node; end
  class SelectorElement < Node; end
end; end; end
