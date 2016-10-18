require 'logstash/util/loggable'
require 'logstash/output_delegator_strategy_registry'

java_import org.logstash.config.pipeline.Pipeline
java_import org.logstash.config.pipeline.PipelineRunner;
java_import org.logstash.config.pipeline.pipette.PipetteExecutionException;
java_import org.logstash.config.pipeline.pipette.PipetteSourceEmitter;
java_import org.logstash.config.ir.graph.Graph;
java_import org.logstash.config.ir.graph.PluginVertex;
java_import java.util.concurrent.SynchronousQueue;
java_import org.logstash.config.compiler.RubyExpressionCompiler;
java_import org.logstash.config.pipeline.pipette.PipetteSourceEmitter

module LogStash; class Compiler
  include ::LogStash::Util::Loggable

  class CompiledRubyInput
    include org.logstash.config.compiler.compiled.ICompiledInputPlugin

    class QueueEmitterAdapter
      def initialize(emitter)
        @emitter = emitter
      end

      def push(event)
        push_batch([event])
      end
      alias_method(:<<, :push)

      def push_batch(events)
        @emitter.emit(events)
      end
    end

    def initialize(plugin, vertex)
      @plugin = plugin
      @vertex = vertex
    end

    def register
      @plugin.register
    end

    def start
      if @emitter.nil?
        raise "Could not start! Emitter not defined! #{self}"
      end
      @plugin.run(QueueEmitterAdapter.new(@emitter))
    end

    def stop
      @plugin.do_stop
    end

    def onEvents(emitter)
      @emitter = emitter
    end
  end

  class CompiledRubyProcessor
    include org.logstash.config.compiler.compiled.ICompiledProcessor

    def initialize(plugin, vertex)
      @plugin = plugin
      @vertex = vertex
      # We run this a lot, so it's easier to just clone this on every
      # Invocation rather than worry about jruby efficiently invoking this method
      @outgoing_edges = vertex.getOutgoingEdges()
    end

    def register
      @plugin.register
    end

    def stop
      @plugin.do_close
    end

    def map_processed(processed)
      result_map = {}
      @outgoing_edges.each {|edge| result_map[edge] = processed}
      result_map
    end
  end

  class CompiledRubyFilter < CompiledRubyProcessor
    def process(events)
      map_processed(@plugin.multi_filter(events))
    end
  end

  class CompiledRubyOutput < CompiledRubyProcessor
    def process(events)
      map_processed(@plugin.multi_receive(events))
    end
  end

  class StandardPluginCompiler
    include ::LogStash::Util::Loggable
    include org.logstash.config.compiler.IPluginCompiler;

    attr_reader :pipeline_id, :pipeline_metric

    def initialize(pipeline_id, pipeline_metric)
      @pipeline_id = pipeline_id
      @pipeline_metric = pipeline_metric
    end

    def compileInput(vertex)
      definition = vertex.getPluginDefinition
      klass = lookup_plugin_class(definition)

      input_plugin = klass.new(definition.getArguments)
      input_plugin.metric = plugin_scoped_metric(definition)

      CompiledRubyInput.new(input_plugin, vertex)
    end

    def compileFilter(vertex)
      definition = vertex.getPluginDefinition
      klass = lookup_plugin_class(definition)
      delegator = FilterDelegator.new(logger, klass, plugin_scoped_metric(definition), definition.getArguments)
      CompiledRubyFilter.new(delegator, vertex)
    end

    def compileOutput(vertex)
      definition = vertex.getPluginDefinition
      klass = lookup_plugin_class(definition)
      delegator = OutputDelegator.new(logger, klass, plugin_scoped_metric(definition),
                                      OutputDelegatorStrategyRegistry.instance,
                                      definition.getArguments)
      CompiledRubyOutput.new(delegator, vertex)
    end

    def plugin_scoped_metric(definition)
      pipeline_metric.namespace([(definition_type_string(definition) + "s").to_sym,
                                  definition.getId()])
    end


    def lookup_plugin_class(definition)
      Plugin.lookup(definition_type_string(definition), definition.getName)
    end

    def definition_type_string(definition)
      definition.getType.to_s.downcase
    end
  end

  def self.compile(config_str, source_file=nil, pipeline_id=nil, metric=nil)
    pipeline_id ||= :main
    metric ||= LogStash::Instrument::NullMetric.new

    pipeline = compile_pipeline(config_str, source_file)
    pipeline_metric = metric.namespace([:stats, :pipelines, pipeline_id.to_s.to_sym, :plugins])
    plugin_compiler = StandardPluginCompiler.new(pipeline_id, pipeline_metric)

    runner = org.logstash.config.pipeline.PipelineRunner.new(
      pipeline, queue, expression_compiler, plugin_compiler, nil
    )
  end

  def self.compile_pipeline(config_str, source_file=nil)
    graph_sections = self.compile_graph(config_str, source_file)
    pipeline = org.logstash.config.pipeline.Pipeline.new(
      graph_sections[:input],
      graph_sections[:filter],
      graph_sections[:output]
    )
  end

  def self.queue
    queue = java.util.concurrent.SynchronousQueue.new
  end

  def self.expression_compiler
    org.logstash.config.compiler.RubyExpressionCompiler.new
  end


  def self.compile_ast(config_str, source_file=nil)
    grammar = LogStashConfigParser.new
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
