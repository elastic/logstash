# encoding: utf-8

module LogStashCompilerLSCLGrammar; module LogStash; module Compiler; module LSCL; module AST
  # Helpers for parsing LSCL files
  module Helpers
    def source_meta
      line, column = line_and_column
      org.logstash.common.SourceWithMetadata.new(base_protocol, base_id, line, column, self.text_value)
    end

    def base_source_with_metadata=(value)
      set_meta(:base_source_with_metadata, value)
    end
    
    def base_source_with_metadata
      get_meta(:base_source_with_metadata)
    end

    def base_protocol
      self.base_source_with_metadata ? self.base_source_with_metadata.protocol : 'config_ast'
    end

    def base_id
      self.base_source_with_metadata ? self.base_source_with_metadata.id : 'config_ast'
    end

    def compose(*statements)
      compose_for(section_type.to_sym).call(source_meta, *statements)
    end

    def compose_for(section_sym)
      if section_sym == :filter
        jdsl.method(:iComposeSequence)
      else
        jdsl.method(:iComposeParallel)
      end
    end

    def line_and_column
      start = self.interval.first
      [self.input.line_of(start), self.input.column_of(start)]
    end

    def jdsl
      org.logstash.config.ir.DSL
    end

    def self.jdsl
      org.logstash.config.ir.DSL
    end
    
    AND_METHOD = jdsl.method(:eAnd)
    NAND_METHOD = jdsl.method(:eNand)
    OR_METHOD = jdsl.method(:eOr)
    XOR_METHOD = jdsl.method(:eXor)
  end
end; end; end; end; end
