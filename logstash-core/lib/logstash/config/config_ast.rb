# encoding: utf-8
require 'logstash/errors'
require "treetop"
java_import Java::OrgLogstashConfigIr::DSL
java_import Java::OrgLogstashConfigIr::SourceMetadata

class Treetop::Runtime::SyntaxNode
  # Traverse the sourceComponent tree recursively.
  # The order should respect the order of the configuration file as it is read
  # and written by humans (and the order in which it is parsed).
  def recurse(e, depth=0, &block)
    r = block.call(e, depth)
    e.elements.each { |e| recurse(e, depth + 1, &block) } if r && e.elements
    nil
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
  
  # When Treetop parses the configuration file
  # it will generate a tree, the generated tree will contain
  # a few `Empty` nodes to represent the actual space/tab or newline in the file.
  # Some of theses node will point to our concrete class.
  # To fetch a specific types of object we need to follow each branch
  # and ignore the empty nodes.
  def recursive_select(*klasses)
    return recursive_inject { |e| klasses.any? {|k| e.is_a?(k)} }
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
  module JDSL                                  
    def source_meta
      line, column = line_and_column
      filename = Thread.current[:current_treetop_filename]
      Java::OrgLogstashConfigIr::SourceMetadata.new(nil, line, column, self.text_value)
    end

    def line_and_column
      lines_to_first_char = self.input[0..self.interval.first].split("\n")

      line = lines_to_first_char.size
      column = lines_to_first_char.last.size
      
      [line, column]
    end
  
    def empty_source_meta()
      Java::OrgLogstashConfigIr::SourceMetadata.new()
    end
    
    def jdsl
      Java::OrgLogstashConfigIr::DSL
    end
  end
  
  class Node < Treetop::Runtime::SyntaxNode
    include JDSL
    
    def text_value_for_comments
      text_value.gsub(/[\r\n]/, " ")
    end

    def ssym(text, meta={})
      SyntaxSymbol.new(text, meta)
    end
  end

  class Config < Node
    def compile(filename="<unknown>")
      # There is no way to move vars across nodes in treetop :(
      Thread.current[:current_treetop_filename] = filename
      
      sections = recursive_select(LogStash::Config::AST::PluginSection)
      
      section_map = {
        :input  => [],
        :filter => [],
        :output => []
      }
            
      sections.each do |section|
        section_name = section.plugin_type.text_value.to_sym
        section_expr = section.expr
        raise "Unknown section name #{section_name}!" if ![:input, :output, :filter].include?(section_name)
        # Don't include nil section exprs!
        ::Array[section_expr].each do |se|
          section_map[section_name].concat se
        end
      end

      # Represent filter / output blocks as a single composed statement
      section_map.keys.each do |key|
        section_map[key] = jdsl.iCompose(empty_source_meta, *section_map[key])
      end
      
      section_map
    end
  end

  class Comment < Node
    def significant
      false
    end

  end
  
  class Whitespace < Node
    def significant
      false
    end
  end
  class PluginSection < Node
    # Global plugin numbering for the janky instance variable naming we use
    # like @filter_<name>_1
    def expr
      [*recursive_select(Branch, Plugin).map(&:expr)]
    end

    def section_type
      self.elements.first.text_value.to_sym
    end
  end

  class Plugins < Node; end
  class Plugin < Node
    def expr
      jdsl.iPlugin(source_meta, self.plugin_name, self.expr_attributes)
    end

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

    def expr_attributes
      # Turn attributes into a hash map
      self.attributes.recursive_select(Attribute).map(&:expr).map {|k,v|
        if v.java_kind_of?(Java::OrgLogstashConfigIrExpression::ValueExpression)
          [k, v.get]
        else
          [k,v]
        end
      }.reduce({}) do |hash,kv|
        k,v = kv
        hash[k] = v
        hash
      end
       
    end
  end

  class Name < Node
    def expr
      return text_value
    end
  end
  class Attribute < Node
    def expr
      [name.text_value, value.expr]
    end
  end
  class RValue < Node; end
  class Value < RValue; end

  class Bareword < Value
    def expr
      jdsl.eValue(source_meta, text_value)
    end
  end
  class String < Value
    def expr
      jdsl.eValue(source_meta, text_value[1...-1])
    end
  end
  class RegExp < Value
    def expr
      jdsl.eRegex(text_value[1..-2])
    end
  end
  class Number < Value
    def expr
      jdsl.eValue(source_meta, text_value.include?(".") ? text_value.to_f : text_value.to_i)
    end
  end
  class Array < Value
    def expr
      jdsl.eValue(source_meta, recursive_select(Value).map(&:expr).map(&:get))
    end
  end
  class Hash < Value
    def validate!
      duplicate_values = find_duplicate_keys

      if duplicate_values.size > 0
        raise ConfigurationError.new(
          I18n.t("logstash.runner.configuration.invalid_plugin_settings_duplicate_keys",
                 :keys => duplicate_values.join(', '),
                 :line => input.line_of(interval.first),
                 :column => input.column_of(interval.first),
                 :byte => interval.first + 1,
                 :after => input[0..interval.first]
                )
        )
      end
    end

    def find_duplicate_keys
      values = recursive_select(HashEntry).collect { |hash_entry| hash_entry.name.text_value }
      values.find_all { |v| values.count(v) > 1 }.uniq
    end

    def expr
      validate!
      ::Hash[recursive_select(HashEntry).map(&:expr)]
    end
  end

  class HashEntries < Node
  end

  class HashEntry < Node
    def expr
      return [name.expr.get, value.expr.get()]
    end
  end

  class Branch < Node
    def expr
      # Build this stuff as s-expressions for convenience at first (they're mutable)
      
      exprs = []
      else_stack = [] # For turning if / elsif / else into nested ifs

      self.recursive_select(Plugin, If, Elsif, Else).each do |node|        
        if node.is_a?(If)
          exprs << :if
          exprs << expr_cond(node)
          exprs << expr_body(node)
        elsif node.is_a?(Elsif)
          condition = expr_cond(node)
          body = expr_body(node)
          
          else_stack << [:if, condition, body]
        elsif node.is_a?(Else)
          body = expr_body(node)
          if else_stack.size >= 1
            else_stack.last << body
          else
            exprs << body
          end
        end
      end

      else_stack.reverse.each_cons(2) do |cons|
        later,earlier = cons
        earlier << later
      end
      exprs << else_stack.first

      # Then convert to the imperative java IR
      javaify_sexpr(exprs)
    end

    def javaify_sexpr(sexpr)
      return nil if sexpr.nil?
      
      head, tail = sexpr.first
      tail = sexpr[1..-1]

      if head == :if
        condition, t_branch, f_branch = tail

        java_t_branch = t_branch && javaify_sexpr(t_branch)
        java_f_branch = f_branch && javaify_sexpr(f_branch)
        
        if java_t_branch || java_f_branch
          # Invert the expression and make the f_branch the t_branch
          
          jdsl.iIf(condition, java_t_branch || jdsl.noop, java_f_branch || jdsl.noop)
        else
          jdsl.noop()
        end
      elsif head == :compose
        tail && tail.size > 0 ? jdsl.iCompose(*tail) : jdsl.noop
      else
        raise "Unknown expression #{head}!"
      end
    end

    def expr_cond(node)
      node.elements.find {|e| e.is_a?(Condition)}.expr
    end

    def expr_body(node)
      [:compose, *node.recursive_select(Plugin, Branch).map(&:expr)]
    end
  end

  class BranchEntry < Node; end

  class If < BranchEntry
  end
  class Elsif < BranchEntry
  end
  class Else < BranchEntry
  end

  class Condition < Node
    def expr
      first_element = elements.first
      rest_elements = elements.size > 1 ? elements[1].recursive_select(BooleanOperator, Expression, SelectorElement) : []

      all_elements = [first_element, *rest_elements]

      if all_elements.size == 1
        elem = all_elements.first
        if elem.is_a?(Selector)
          eventValue = elem.recursive_select(SelectorElement).first.expr
          jdsl.eNotNull(eventValue)
        elsif elem.is_a?(RegexpExpression)
          elem.value
        else
          join_conditions(all_elements)
        end
      else
      
        join_conditions(all_elements) # Is this necessary?
      end 
    end

    def precedence(op)
      #  Believe this is right for logstash?
      case op
      when :and
        2
      when :or
        1
      else
        raise ArgumentError, "Unexpected operator #{op}"
      end
    end

    def jconvert(sexpr)
      return sexpr if sexpr.java_kind_of?(Java::OrgLogstashConfigIrExpression::BooleanExpression)
      
      op, left, right = sexpr
      jop = case op
            when :and
              org.logstash.config.ir.expression.BinaryBooleanExpression::Operator::AND
            when :or
              org.logstash.config.ir.expression.BinaryBooleanExpression::Operator::OR
            else
              raise "Unknown op #{jop}"
            end

      right_converted = right(left) if right.is_a?(Array)
      jdsl.eBinaryBoolean(jop, jconvert(left), jconvert(right))
    end

    def join_conditions(all_elements)
      # Use Dijkstra's shunting yard algorithm
      out = []
      operators = []

      all_elements.each do |e|
        e_exp = e.expr

        if e.is_a?(BooleanOperator)
          if operators.last && precedence(operators.last) > precedence(e_exp)
            out << operators.pop
          end
          operators << e_exp
        else
          out << e_exp
        end
      end
      operators.reverse.each {|o| out << o}

      stack = []
      expr = []
      x = false
      out.each do |e|
        if e.is_a?(Symbol)
          x = 1
          rval, lval = stack.pop, stack.pop
          stack << jconvert([e, lval, rval])
        else
          stack << e
        end
      end

      if stack.size > 1
        raise "Stack size should never be > than 1!"
      end
      return stack.first
    end
  end

  module Expression
    def expr
      return self.value if self.respond_to?(:value) 

      self.recursive_select(Condition, Expression).map {|e| e.respond_to?(:value) ? e.value : e.expr }.first
    end
  end

  module NegativeExpression
    include JDSL
    
    def value
      jdsl.eNot(self.recursive_select(Condition).map(&:expr).first)
    end
  end

  module ComparisonExpression
    include JDSL
    
    def value
      lval, op, rval = self.recursive_select(Selector, ComparisonOperator, Number, String).map(&:expr)
      jdsl.eBinaryBoolean(source_meta, op, lval, rval)
    end
  end

  module InExpression
    include JDSL
    
    def value # Because this is somehow higher up the inheritance chain than Expression
      item, list = recursive_select(LogStash::Config::AST::RValue)
      jdsl.eIn(item.expr, list.expr)
    end
  end

  module NotInExpression
    include JDSL
    
    def value
      item, list = recursive_select(LogStash::Config::AST::RValue)
      jdsl.eNot(jdsl.eIn(item.expr, list.expr))
    end
  end

  class MethodCall < Node
    # TBD: Can we delete this? Who uses the method call syntax?
    def compile
      arguments = recursive_inject { |e| [String, Number, Selector, Array, MethodCall].any? { |c| e.is_a?(c) } }
      return "#{method.text_value}(" << arguments.collect(&:compile).join(", ") << ")"
    end
  end

  class RegexpExpression < Node
    def value
      selector, operator, regexp = recursive_select(Selector, LogStash::Config::AST::RegExpOperator, LogStash::Config::AST::RegExp).map(&:expr)

      raise "Expected a selector #{text_value}!" unless selector
      raise "Expected a regexp #{text_value}!" unless regexp

      jdsl.eBinaryBoolean(source_meta, operator, selector, regexp)
    end
  end

  module BranchOrPlugin; end
  
  module ComparisonOperator
    include JDSL
    
    def expr
      operators = org.logstash.config.ir.expression.BinaryBooleanExpression::Operator
      case self.text_value
      when "=="
        operators::EQ
      when "!="
        operators::NEQ
      when ">"
        operators::GT
      when "<"
        operators::LT
      when ">="
        operators::GTE
      when "<="
        operators::LTE
      else
        raise "Unknown operator #{self.text_value}"
      end
    end
  end
  module RegExpOperator
    def expr
      if self.text_value == '!~'
        org.logstash.config.ir.expression.BinaryBooleanExpression::Operator::REGEXPNEQ
      elsif self.text_value == '=~'
        org.logstash.config.ir.expression.BinaryBooleanExpression::Operator::REGEXPEQ
      else
        raise "Unknown regex operator #{self.text_value}"
      end
    end    
  end
  module BooleanOperator
    def expr
      self.text_value.to_sym
    end
  end
  class Selector < RValue
    def expr
      jdsl.eEventValue(source_meta, text_value)
    end
  end
  class SelectorElement < Node;
    def expr
      jdsl.eEventValue(source_meta, text_value)
    end
  end
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
