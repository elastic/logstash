# encoding: utf-8
require "thread_safe"
require "forwardable"

module LogStash
  module StringInterpolation
    extend self

    # Floats outside of these upper and lower bounds are forcibly converted
    # to scientific notation by Float#to_s
    MIN_FLOAT_BEFORE_SCI_NOT = 0.0001
    MAX_FLOAT_BEFORE_SCI_NOT = 1000000000000000.0

    CACHE = ThreadSafe::Cache.new
    TEMPLATE_TAG_REGEXP = /%\{[^}]+\}/

    def evaluate(event, template)
      if template.is_a?(Float) && (template < MIN_FLOAT_BEFORE_SCI_NOT || template >= MAX_FLOAT_BEFORE_SCI_NOT)
        return ("%.15f" % template).sub(/0*$/,"")
      end

      template = template.to_s

      return template if not_cachable?(template)

      compiled = CACHE.get_or_default(template, nil) || CACHE.put(template, compile_template(template))
      compiled.evaluate(event)
    end

    # clear the global compiled templates cache
    def clear_cache
      CACHE.clear
    end

    # @return [Fixnum] the compiled templates cache size
    def cache_size
      CACHE.size
    end

    private
    def not_cachable?(template)
      template.index("%").nil?
    end

    def compile_template(template)
      nodes = Template.new

      position = 0
      matches = template.to_enum(:scan, TEMPLATE_TAG_REGEXP).map { |m| $~ }

      matches.each do |match|
        tag = match[0][2..-2]
        start = match.offset(0).first
        nodes << StaticNode.new(template[position..(start-1)]) if start > 0
        nodes << identify(tag)
        position = match.offset(0).last
      end

      if position < template.size
        nodes << StaticNode.new(template[position..-1])
      end

      optimize(nodes)
    end

    def optimize(nodes)
      nodes.size == 1 ?  nodes.first : nodes
    end

    def identify(tag)
      if tag == "+%s"
        EpocNode.new
      elsif tag[0, 1] == "+"
        DateNode.new(tag[1..-1])
      else
        KeyNode.new(tag)
      end
    end
  end

  class Template
    extend Forwardable
    def_delegators :@nodes, :<<, :push, :size, :first

    def initialize
      @nodes = []
    end

    def evaluate(event)
      @nodes.collect { |node| node.evaluate(event) }.join
    end
  end

  class EpocNode
    def evaluate(event)
      t = event.timestamp
      raise LogStash::Error, "Unable to format in string \"#{@format}\", #{LogStash::Event::TIMESTAMP} field not found" unless t
      t.to_i.to_s
    end
  end

  class StaticNode
    def initialize(content)
      @content = content
    end

    def evaluate(event)
      @content
    end
  end

  class KeyNode
    def initialize(key)
      @key = key
    end

    def evaluate(event)
      value = event[@key]

      case value
      when nil
        "%{#{@key}}"
      when Array
        value.join(",")
      when Hash
        LogStash::Json.dump(value)
      else
        value
      end
    end
  end

  class DateNode
    def initialize(format)
      @format = format
      @formatter = org.joda.time.format.DateTimeFormat.forPattern(@format)
          .withZone(org.joda.time.DateTimeZone::UTC)
    end

    def evaluate(event)
      t = event.timestamp

      raise LogStash::Error, "Unable to format in string \"#{@format}\", #{LogStash::Event::TIMESTAMP} field not found" unless t

      org.joda.time.Instant.java_class.constructor(Java::long).new_instance(
        t.tv_sec * 1000 + t.tv_usec / 1000
      ).to_java.toDateTime.toString(@formatter)
    end
  end
end
