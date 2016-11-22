require 'logstash/util/loggable'
require 'logstash/compiler/lscl/lscl_grammar'

java_import org.logstash.config.ir.Pipeline
java_import org.logstash.config.ir.graph.Graph;
java_import org.logstash.config.ir.graph.PluginVertex;

module LogStash; class Compiler
  include ::LogStash::Util::Loggable

  def self.compile_pipeline(config_str, source_file=nil)
    graph_sections = self.compile_graph(config_str, source_file)
    pipeline = org.logstash.config.ir.Pipeline.new(
      graph_sections[:input],
      graph_sections[:filter],
      graph_sections[:output]
    )
  end

  def self.compile_ast(config_str, source_file=nil)
    grammar = LogStashCompilerLSCLGrammarParser.new
    config = grammar.parse(config_str)

    if config.nil?
      raise ConfigurationError, grammar.failure_reason
    end

    config
  end

  def self.compile_imperative(config_str, source_file=nil)
    compile_ast(config_str, source_file).compile(source_file)
  end

  def self.compile_graph(config_str, source_file=nil)
    Hash[compile_imperative(config_str, source_file).map {|section,icompiled| [section, icompiled.toGraph]}]
  end
end; end
