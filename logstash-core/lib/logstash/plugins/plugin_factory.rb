# encoding: utf-8

module LogStash
  module Plugins

    class ExecutionContextFactory

      def initialize(agent, pipeline, dlq_writer)
        @agent = agent
        @pipeline = pipeline
        @dlq_writer = dlq_writer
      end

      def create(id, klass_cfg_name)
        ExecutionContext.new(@pipeline, @agent, id, klass_cfg_name, @dlq_writer)
      end
    end

    class PluginMetricFactory

      def initialize(pipeline_id, metric)
        @pipeline_id = pipeline_id.to_s.to_sym
        @metric = metric
      end

      def create(plugin_type)
        @metric.namespace([:stats, :pipelines, @pipeline_id, :plugins])
          .namespace("#{plugin_type}s".to_sym)
      end
    end

    class PluginFactory
      include org.logstash.config.ir.compiler.RubyIntegration::PluginFactory

      def initialize(lir, metric_factory, exec_factory, filter_class)
        @lir = lir
        @plugins_by_id = {}
        @metric_factory = metric_factory
        @exec_factory = exec_factory
        @filter_class = filter_class
      end

      def buildOutput(name, line, column, *args)
        plugin("output", name, line, column, *args)
      end

      def buildFilter(name, line, column, *args)
        plugin("filter", name, line, column, *args)
      end

      def buildInput(name, line, column, *args)
        plugin("input", name, line, column, *args)
      end

      def buildCodec(name, *args)
        plugin("codec", name, 0, 0, *args)
      end

      def plugin(plugin_type, name, line, column, *args)
        # Collapse the array of arguments into a single merged hash
        args = args.reduce({}, &:merge)

        if plugin_type == "codec"
          id = SecureRandom.uuid # codecs don't really use their IDs for metrics, so we can use anything here
        else
          # Pull the ID from LIR to keep IDs consistent between the two representations
          id = @lir.graph.vertices.filter do |v|
            v.source_with_metadata &&
              v.source_with_metadata.line == line &&
              v.source_with_metadata.column == column
          end.findFirst.get.id
        end
        args["id"] = id # some code pulls the id out of the args

        raise ConfigurationError, "Could not determine ID for #{plugin_type}/#{plugin_name}" unless id
        raise ConfigurationError, "Two plugins have the id '#{id}', please fix this conflict" if @plugins_by_id[id]

        @plugins_by_id[id] = true
        # Scope plugins of type 'input' to 'inputs'
        type_scoped_metric = @metric_factory.create(plugin_type)
        klass = Plugin.lookup(plugin_type, name)
        execution_context = @exec_factory.create(id, klass.config_name)

        if plugin_type == "output"
          OutputDelegator.new(klass, type_scoped_metric, execution_context, OutputDelegatorStrategyRegistry.instance, args)
        elsif plugin_type == "filter"
          @filter_class.new(klass, type_scoped_metric, execution_context, args)
        else # input or codec plugin
          plugin_instance = klass.new(args)
          scoped_metric = type_scoped_metric.namespace(id.to_sym)
          scoped_metric.gauge(:name, plugin_instance.config_name)
          plugin_instance.metric = scoped_metric
          plugin_instance.execution_context = execution_context
          plugin_instance
        end
      end
    end
  end
end
