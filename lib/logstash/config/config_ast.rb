# encoding: utf-8
require "json"
require "treetop"

class Treetop::Runtime::SyntaxNode
  def to_ruby
    return "" if elements.nil?
    return elements.collect(&:to_ruby).reject(&:empty?).join
  end

  # Skip any Whitespace or SyntaxNodes with no children.
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

module LogStash; module Config; module AST
  class NodeArray < Array
    def to_ruby(join_with=nil, &block)
      pieces = map(&:to_ruby).reject(&:empty?)
      pieces.map!(&block) if block_given?
      if join_with
        return pieces.join(join_with)
      else
        return pieces
      end
    end
  end

  class SyntaxNode < Treetop::Runtime::SyntaxNode
    def json_parse_value(jsonstr)
      JSON.parse("[ #{jsonstr} ]").first
    end

    def items
      @items ||= compute_items
    end

    def find_ancestor(klass=nil, &block)
      this = parent
      while this
        return this if (!klass || this.is_a?(klass)) && (!block_given? || block.call(this))
        this = this.parent
      end
    end

    def each_plugin(&block)
      if elements
        elements.
          select { |elt| elt.respond_to?(:each_plugin) }.
          each { |elt| elt.each_plugin(&block)  }
      end
    end

    private

    def compute_items
      items = NodeArray.new([
        *( _item if respond_to?(:_item) ),
        *( elements.select { |e| e.respond_to?(:_item) }.map(&:_item) if elements ),
        *( _items.items if respond_to?(:_items) ) ])
      items.compact!
      items.uniq!
      return items
    end
  end

  class Whitespace < Treetop::Runtime::SyntaxNode; end

  class Config < SyntaxNode
    def to_ruby
      # TODO(sissel): Move this into config/config_ast.rb
      code = []
      code << "@inputs = []"
      code << "@filters = []"
      code << "@outputs = []"
      items.each do |s|
        code << s.initializer_ruby
      end

      ["filter", "output"].each do |type|
        code << "@#{type}_func = lambda do |event, &block|"
        if type == "filter"
          code << "  extra_events = []"
        end

        code << "  @logger.info? && @logger.info(\"#{type} received\", :event => event)"
        items.select { |s| s.type == type }.each do |s|
          code << s.to_ruby.gsub(/^/m, '  ')
        end

        if type == "filter"
          code << "  extra_events.each(&block)"
        end
        code << "end\n"
      end

      return code.join("\n")
    end
  end

  class PluginSection < SyntaxNode
    @@i = 0

    def type
      plugin_type.text_value
    end

    # Generate ruby code to initialize all the plugins.
    def initializer_ruby
      generate_variables
      code = []
      @variables.collect do |plugin, name|
        code << "#{name} = #{plugin.initializer_ruby}"
        code << "@#{plugin.type}s << #{name}"
      end
      return code.join("\n")
    end

    def [](object)
      generate_variables
      return @variables[object]
    end

    def generate_variables
      return if !@variables.nil?
      @variables = {}

      each_plugin do |plugin|
        # Unique number for every plugin.
        @@i += 1
        # store things as ivars, like @filter_grok_3
        var = "@#{plugin.type}_#{plugin.plugin_name}_#{@@i}"
        @variables[plugin] = var
      end
      return @variables
    end
  end

  class Plugin < SyntaxNode
    def type
      # If any parent is a Plugin, this must be a codec.
      @type ||= find_ancestor(Plugin) ? "codec" : section.type
    end

    def plugin_name
      return name.text_value
    end

    def variable_name
      return section[self]
    end

    def initializer_ruby
      if items.empty?
        return "plugin(#{type.inspect}, #{plugin_name.inspect})" << (type == "codec" ? "" : "\n")
      else
        return "plugin(#{type.inspect}, #{plugin_name.inspect}, #{attributes_ruby})" << (type == "codec" ? "" : "\n")
      end
    end

    def to_ruby
      case type
        when "input"
          return "start_input(#{variable_name})"
        when "filter"
          # This is some pretty stupid code, honestly.
          # I'd prefer much if it were put into the Pipeline itself
          # and this should simply to_ruby to 
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
          ].join("\n") << "\n"
        when "output"
          return "#{variable_name}.handle(event)\n"
        when "codec"
          return "plugin(#{type.inspect}, #{plugin_name.inspect}, #{attributes_ruby})"
      end
    end

    def each_plugin
      yield self
    end

    private

    def section
      @section ||= find_ancestor(PluginSection)
    end

    def attributes_ruby
      attributes = items.to_ruby(', ') { |c| "{ #{c} }" }
      return "LogStash::Util.hash_merge_many(#{attributes})"
    end
  end

  # Mixin modules

  module Regexped
    def to_ruby
      "Regexp.new(#{super})"
    end
  end

  module Parenthesised
    def to_ruby
      "(#{super})"
    end
  end

  # A simple, unquoted value. If `content` method or named symbol is
  # defined, then its value is used (`text_value` if it reponds to
  # that, raw value otherwise). If `content` is not defined,
  # `text_value` is used.
  class Value < SyntaxNode
    def to_ruby
      if respond_to?(:content)
        if content.respond_to?(:text_value)
           content.text_value
        else
          content
        end
      else
        text_value
      end
    end
  end

  # A value quoted as a Unicode string.
  class UnicodeValue < Value
    def to_ruby
      "(#{super.inspect}.force_encoding(\"UTF-8\"))"
    end
  end

  # A Regexp instance
  class RegexpValue < UnicodeValue
    include Regexped
  end

  # Composite value: an array or a hash.
  class CompositeValue < Value
    def to_ruby
      "#{elements.first.text_value} #{items.to_ruby(', ')} #{elements.last.text_value}"
    end
  end

  # A key/value pair, in attribute list or in a hash value.
  class KVPair < SyntaxNode
    def to_ruby
      return "#{name.to_ruby} => #{value.to_ruby}"
    end
  end

  # Conditionals

  # A complete if / else if / else if / else set
  class BranchSet < SyntaxNode
    def to_ruby
      "#{super}end\n"
    end
  end

  # A single if, else if, or else branch
  class Branch < SyntaxNode
    def keyword
      elements.first.text_value
    end

    def to_ruby
      "#{keyword}#{' ' << condition.to_ruby if respond_to?(:condition)}\n#{branch_body.to_ruby}\n"
    end
  end

  # Actual body of a branch
  class BranchBody < SyntaxNode
    def to_ruby
      body.elements.map do |child|
        child.branch_or_plugin.to_ruby.gsub(/^/m, '  ')
      end.join
    end
  end

  class InExpression < SyntaxNode
    def to_ruby
      "#{'!' if negated && !negated.empty?}(x = #{haystack.to_ruby}; x.respond_to?(:include?) && x.include?(#{needle.to_ruby}))"
    end
  end

  class MethodCall < SyntaxNode
    def to_ruby
      "#{method.text_value}(#{items.to_ruby(', ')})"
    end
  end

  class Operator < SyntaxNode
    def to_ruby
      return " #{text_value} "
    end
  end

  class Selector < SyntaxNode
    def to_ruby
      return "event[#{text_value.inspect}]"
    end
  end
end; end; end
