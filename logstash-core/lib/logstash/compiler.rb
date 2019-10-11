require 'logstash/compiler/lscl/lscl_grammar'

java_import org.logstash.config.ir.PipelineIR
java_import org.logstash.config.ir.graph.Graph

module LogStash; class Compiler
  include ::LogStash::Util::Loggable

  def self.compile_sources(pipeline_config, support_escapes)
    sources_with_metadata = [org.logstash.common.SourceWithMetadata.new("str", "pipeline", 0, 0, pipeline_config.config_string)]
    graph_sections = sources_with_metadata.map do |swm|
      self.compile_graph(pipeline_config, swm, support_escapes)
    end

    input_graph = Graph.combine(*graph_sections.map {|s| s[:input] }).graph
    output_graph = Graph.combine(*graph_sections.map {|s| s[:output] }).graph

    filter_graph = graph_sections.reduce(nil) do |acc, s|
      filter_section = s[:filter]

      if acc.nil?
        filter_section
      else
        acc.chain(filter_section)
      end
    end

    original_source = sources_with_metadata.map(&:text).join("\n")

    PipelineIR.new(input_graph, filter_graph, output_graph, original_source)
  end

  def self.compile_imperative(pipeline_config, source_with_metadata, support_escapes)
    if !source_with_metadata.is_a?(org.logstash.common.SourceWithMetadata)
      raise ArgumentError, "Expected 'org.logstash.common.SourceWithMetadata', got #{source_with_metadata.class}"
    end

    grammar = LogStashCompilerLSCLGrammarParser.new
    config = grammar.parse(source_with_metadata.text)

    if config.nil?
      raise ConfigurationError, grammar.failure_reason
    end

    plugins = config.recursive_select(LogStashCompilerLSCLGrammar::LogStash::Compiler::LSCL::AST::Plugin)
    added_source_line_column(pipeline_config, plugins)

    config.process_escape_sequences = support_escapes
    config.compile(source_with_metadata)
  end

  def self.compile_graph(pipeline_config, source_with_metadata, support_escapes)
    Hash[compile_imperative(pipeline_config, source_with_metadata, support_escapes).map {|section,icompiled| [section, icompiled.toGraph]}]
  end

  def self.added_source_line_column(pipeline_config, plugins)
    for plugin in plugins do
      remapped_line = pipeline_config.lookup_source_and_line(plugin.line_and_column[0])
      plugin.source_file = remapped_line[0]
      plugin.source_line = remapped_line[1]
    end
  end

end; end
