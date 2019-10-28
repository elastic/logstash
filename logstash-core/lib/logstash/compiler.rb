require 'logstash/compiler/lscl/lscl_grammar'

java_import org.logstash.config.ir.PipelineIR
java_import org.logstash.config.ir.ConfigCompiler
java_import org.logstash.config.ir.graph.Graph

module LogStash; class Compiler
  include ::LogStash::Util::Loggable

  # Used only in lir_serializer_spec
  def self.compile_sources(sources_with_metadata, support_escapes)
    ConfigCompiler.compileSources(sources_with_metadata, support_escapes)
  end

  def self.compile_imperative(source_with_metadata, support_escapes)
    if !source_with_metadata.is_a?(org.logstash.common.SourceWithMetadata)
      raise ArgumentError, "Expected 'org.logstash.common.SourceWithMetadata', got #{source_with_metadata.class}"
    end

    grammar = LogStashCompilerLSCLGrammarParser.new
    config = grammar.parse(source_with_metadata.text)

    if config.nil?
      raise ConfigurationError, grammar.failure_reason
    end

    config.process_escape_sequences = support_escapes
    config.compile(source_with_metadata)
  end

end; end
