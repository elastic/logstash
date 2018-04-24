package org.logstash;

import org.jruby.NativeException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ObjectAllocator;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;
import org.logstash.ackedqueue.ext.JRubyWrappedAckedQueueExt;
import org.logstash.common.AbstractDeadLetterQueueWriterExt;
import org.logstash.common.BufferedTokenizerExt;
import org.logstash.config.ir.compiler.FilterDelegatorExt;
import org.logstash.config.ir.compiler.OutputDelegatorExt;
import org.logstash.config.ir.compiler.OutputStrategyExt;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.execution.QueueReadClientBase;
import org.logstash.ext.JRubyWrappedWriteClientExt;
import org.logstash.ext.JrubyAckedReadClientExt;
import org.logstash.ext.JrubyAckedWriteClientExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.ext.JrubyMemoryReadClientExt;
import org.logstash.ext.JrubyMemoryWriteClientExt;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.logstash.ext.JrubyWrappedSynchronousQueueExt;
import org.logstash.instrument.metrics.MetricExt;
import org.logstash.instrument.metrics.NamespacedMetricExt;

/**
 * Utilities around interaction with the {@link Ruby} runtime.
 */
public final class RubyUtil {

    /**
     * Reference to the global {@link Ruby} runtime.
     */
    public static final Ruby RUBY;

    public static final RubyClass RUBY_EVENT_CLASS;

    public static final RubyClass RUBY_TIMESTAMP_CLASS;

    public static final RubyClass PARSER_ERROR;

    public static final RubyClass GENERATOR_ERROR;

    public static final RubyClass LOGSTASH_ERROR;

    public static final RubyClass TIMESTAMP_PARSER_ERROR;

    public static final RubyClass WRAPPED_WRITE_CLIENT_CLASS;

    public static final RubyClass QUEUE_READ_CLIENT_BASE_CLASS;

    public static final RubyClass MEMORY_READ_CLIENT_CLASS;

    public static final RubyClass ACKED_READ_CLIENT_CLASS;

    public static final RubyClass MEMORY_WRITE_CLIENT_CLASS;

    public static final RubyClass ACKED_WRITE_CLIENT_CLASS;

    public static final RubyClass WRAPPED_SYNCHRONOUS_QUEUE_CLASS;

    public static final RubyClass WRAPPED_ACKED_QUEUE_CLASS;

    public static final RubyClass ACKED_QUEUE_CLASS;

    public static final RubyClass OUTPUT_DELEGATOR_CLASS;

    public static final RubyClass FILTER_DELEGATOR_CLASS;

    public static final RubyClass OUTPUT_STRATEGY_REGISTRY;

    public static final RubyClass OUTPUT_STRATEGY_ABSTRACT;

    public static final RubyClass OUTPUT_STRATEGY_SIMPLE_ABSTRACT;

    public static final RubyClass OUTPUT_STRATEGY_LEGACY;

    public static final RubyClass OUTPUT_STRATEGY_SINGLE;

    public static final RubyClass OUTPUT_STRATEGY_SHARED;

    public static final RubyClass BUFFERED_TOKENIZER;

    public static final RubyClass METRIC_CLASS;

    public static final RubyClass NAMESPACED_METRIC_CLASS;

    public static final RubyClass METRIC_EXCEPTION_CLASS;

    public static final RubyClass METRIC_NO_KEY_PROVIDED_CLASS;

    public static final RubyClass METRIC_NO_BLOCK_PROVIDED_CLASS;

    public static final RubyClass METRIC_NO_NAMESPACE_PROVIDED_CLASS;

    public static final RubyClass TIMED_EXECUTION_CLASS;

    public static final RubyClass ABSTRACT_DLQ_WRITER_CLASS;

    public static final RubyClass DUMMY_DLQ_WRITER_CLASS;

    public static final RubyClass PLUGIN_DLQ_WRITER_CLASS;

    public static final RubyClass EXECUTION_CONTEXT_CLASS;

    /**
     * Logstash Ruby Module.
     */
    private static final RubyModule LOGSTASH_MODULE;

    private static final RubyModule OUTPUT_DELEGATOR_STRATEGIES;

    static {
        RUBY = Ruby.getGlobalRuntime();
        LOGSTASH_MODULE = RUBY.getOrCreateModule("LogStash");
        final RubyModule instrumentModule =
            RUBY.defineModuleUnder("Instrument", LOGSTASH_MODULE);
        METRIC_EXCEPTION_CLASS = instrumentModule.defineClassUnder(
            "MetricException", RUBY.getException(), MetricExt.MetricException::new
        );
        METRIC_NO_KEY_PROVIDED_CLASS = instrumentModule.defineClassUnder(
            "MetricNoKeyProvided", METRIC_EXCEPTION_CLASS, MetricExt.MetricNoKeyProvided::new
        );
        METRIC_NO_BLOCK_PROVIDED_CLASS = instrumentModule.defineClassUnder(
            "MetricNoBlockProvided", METRIC_EXCEPTION_CLASS,
            MetricExt.MetricNoBlockProvided::new
        );
        METRIC_NO_NAMESPACE_PROVIDED_CLASS = instrumentModule.defineClassUnder(
            "MetricNoNamespaceProvided", METRIC_EXCEPTION_CLASS,
            MetricExt.MetricNoNamespaceProvided::new
        );
        METRIC_CLASS
            = instrumentModule.defineClassUnder("Metric", RUBY.getObject(), MetricExt::new);
        TIMED_EXECUTION_CLASS = METRIC_CLASS.defineClassUnder(
            "TimedExecution", RUBY.getObject(), MetricExt.TimedExecution::new
        );
        NAMESPACED_METRIC_CLASS = instrumentModule.defineClassUnder(
            "NamespacedMetric", RUBY.getObject(), NamespacedMetricExt::new
        );
        METRIC_CLASS.defineAnnotatedMethods(MetricExt.class);
        NAMESPACED_METRIC_CLASS.defineAnnotatedMethods(NamespacedMetricExt.class);
        TIMED_EXECUTION_CLASS.defineAnnotatedMethods(MetricExt.TimedExecution.class);
        final RubyModule util = LOGSTASH_MODULE.defineModuleUnder("Util");
        ABSTRACT_DLQ_WRITER_CLASS = util.defineClassUnder(
            "AbstractDeadLetterQueueWriterExt", RUBY.getObject(),
            ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR
        );
        ABSTRACT_DLQ_WRITER_CLASS.defineAnnotatedMethods(AbstractDeadLetterQueueWriterExt.class);
        DUMMY_DLQ_WRITER_CLASS = util.defineClassUnder(
            "DummyDeadLetterQueueWriter", ABSTRACT_DLQ_WRITER_CLASS,
            AbstractDeadLetterQueueWriterExt.DummyDeadLetterQueueWriterExt::new
        );
        DUMMY_DLQ_WRITER_CLASS.defineAnnotatedMethods(
            AbstractDeadLetterQueueWriterExt.DummyDeadLetterQueueWriterExt.class
        );
        PLUGIN_DLQ_WRITER_CLASS = util.defineClassUnder(
            "PluginDeadLetterQueueWriter", ABSTRACT_DLQ_WRITER_CLASS,
            AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt::new
        );
        PLUGIN_DLQ_WRITER_CLASS.defineAnnotatedMethods(
            AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt.class
        );
        OUTPUT_STRATEGY_REGISTRY = setupLogstashClass(
            OutputStrategyExt.OutputStrategyRegistryExt::new,
            OutputStrategyExt.OutputStrategyRegistryExt.class
        );
        BUFFERED_TOKENIZER = RUBY.getOrCreateModule("FileWatch").defineClassUnder(
            "BufferedTokenizer", RUBY.getObject(), BufferedTokenizerExt::new
        );
        BUFFERED_TOKENIZER.defineAnnotatedMethods(BufferedTokenizerExt.class);
        OUTPUT_DELEGATOR_STRATEGIES =
            RUBY.defineModuleUnder("OutputDelegatorStrategies", LOGSTASH_MODULE);
        OUTPUT_STRATEGY_ABSTRACT = OUTPUT_DELEGATOR_STRATEGIES.defineClassUnder(
            "AbstractStrategy", RUBY.getObject(), ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR
        );
        OUTPUT_STRATEGY_SIMPLE_ABSTRACT = OUTPUT_DELEGATOR_STRATEGIES.defineClassUnder(
            "SimpleAbstractStrategy", OUTPUT_STRATEGY_ABSTRACT,
            ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR
        );
        OUTPUT_STRATEGY_LEGACY = OUTPUT_DELEGATOR_STRATEGIES.defineClassUnder(
            "Legacy", OUTPUT_STRATEGY_ABSTRACT,
            OutputStrategyExt.LegacyOutputStrategyExt::new
        );
        OUTPUT_STRATEGY_SINGLE = OUTPUT_DELEGATOR_STRATEGIES.defineClassUnder(
            "Single", OUTPUT_STRATEGY_SIMPLE_ABSTRACT,
            OutputStrategyExt.SingleOutputStrategyExt::new
        );
        OUTPUT_STRATEGY_SHARED = OUTPUT_DELEGATOR_STRATEGIES.defineClassUnder(
            "Shared", OUTPUT_STRATEGY_SIMPLE_ABSTRACT,
            OutputStrategyExt.SharedOutputStrategyExt::new
        );
        OUTPUT_STRATEGY_ABSTRACT.defineAnnotatedMethods(OutputStrategyExt.AbstractOutputStrategyExt.class);
        OUTPUT_STRATEGY_ABSTRACT.defineAnnotatedMethods(OutputStrategyExt.SimpleAbstractOutputStrategyExt.class);
        OUTPUT_STRATEGY_SHARED.defineAnnotatedMethods(OutputStrategyExt.SharedOutputStrategyExt.class);
        OUTPUT_STRATEGY_SINGLE.defineAnnotatedMethods(OutputStrategyExt.SingleOutputStrategyExt.class);
        OUTPUT_STRATEGY_LEGACY.defineAnnotatedMethods(OutputStrategyExt.LegacyOutputStrategyExt.class);
        final OutputStrategyExt.OutputStrategyRegistryExt outputStrategyRegistry =
            OutputStrategyExt.OutputStrategyRegistryExt.instance(
                RUBY.getCurrentContext(), OUTPUT_DELEGATOR_STRATEGIES
            );
        outputStrategyRegistry.register(
            RUBY.getCurrentContext(), RUBY.newSymbol("shared"), OUTPUT_STRATEGY_SHARED
        );
        outputStrategyRegistry.register(
            RUBY.getCurrentContext(), RUBY.newSymbol("legacy"), OUTPUT_STRATEGY_LEGACY
        );
        outputStrategyRegistry.register(
            RUBY.getCurrentContext(), RUBY.newSymbol("single"), OUTPUT_STRATEGY_SINGLE
        );
        EXECUTION_CONTEXT_CLASS = setupLogstashClass(
            ExecutionContextExt::new, ExecutionContextExt.class
        );
        RUBY_TIMESTAMP_CLASS = setupLogstashClass(
            JrubyTimestampExtLibrary.RubyTimestamp::new, JrubyTimestampExtLibrary.RubyTimestamp.class
        );
        WRAPPED_WRITE_CLIENT_CLASS =
            setupLogstashClass(JRubyWrappedWriteClientExt::new, JRubyWrappedWriteClientExt.class);
        QUEUE_READ_CLIENT_BASE_CLASS =
            setupLogstashClass(ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, QueueReadClientBase.class);
        MEMORY_READ_CLIENT_CLASS =
            setupLogstashClass(QUEUE_READ_CLIENT_BASE_CLASS, JrubyMemoryReadClientExt::new, JrubyMemoryReadClientExt.class);
        ACKED_READ_CLIENT_CLASS =
            setupLogstashClass(QUEUE_READ_CLIENT_BASE_CLASS, JrubyAckedReadClientExt::new, JrubyAckedReadClientExt.class);
        MEMORY_WRITE_CLIENT_CLASS =
            setupLogstashClass(JrubyMemoryWriteClientExt::new, JrubyMemoryWriteClientExt.class);
        ACKED_WRITE_CLIENT_CLASS =
            setupLogstashClass(JrubyAckedWriteClientExt::new, JrubyAckedWriteClientExt.class);
        WRAPPED_SYNCHRONOUS_QUEUE_CLASS =
            setupLogstashClass(JrubyWrappedSynchronousQueueExt::new,
                JrubyWrappedSynchronousQueueExt.class);
        WRAPPED_ACKED_QUEUE_CLASS = setupLogstashClass(JRubyWrappedAckedQueueExt::new,
            JRubyWrappedAckedQueueExt.class);
        ACKED_QUEUE_CLASS = setupLogstashClass(JRubyAckedQueueExt::new, JRubyAckedQueueExt.class);
        RUBY_EVENT_CLASS = setupLogstashClass(
            JrubyEventExtLibrary.RubyEvent::new, JrubyEventExtLibrary.RubyEvent.class
        );
        OUTPUT_DELEGATOR_CLASS = setupLogstashClass(
            OutputDelegatorExt::new, OutputDelegatorExt.class
        );
        FILTER_DELEGATOR_CLASS = setupLogstashClass(
            FilterDelegatorExt::new, FilterDelegatorExt.class
        );
        final RubyModule json = LOGSTASH_MODULE.defineOrGetModuleUnder("Json");
        final RubyClass stdErr = RUBY.getStandardError();
        LOGSTASH_ERROR = LOGSTASH_MODULE.defineClassUnder(
            "Error", stdErr, RubyUtil.LogstashRubyError::new
        );
        PARSER_ERROR = json.defineClassUnder(
            "ParserError", LOGSTASH_ERROR, RubyUtil.LogstashRubyParserError::new
        );
        TIMESTAMP_PARSER_ERROR = LOGSTASH_MODULE.defineClassUnder(
            "TimestampParserError", stdErr, RubyUtil.LogstashTimestampParserError::new
        );
        GENERATOR_ERROR = json.defineClassUnder("GeneratorError", LOGSTASH_ERROR,
            RubyUtil.LogstashRubyGeneratorError::new
        );
        RUBY_EVENT_CLASS.setConstant("METADATA", RUBY.newString(Event.METADATA));
        RUBY_EVENT_CLASS.setConstant(
            "METADATA_BRACKETS", RUBY.newString(Event.METADATA_BRACKETS)
        );
        RUBY_EVENT_CLASS.setConstant("TIMESTAMP", RUBY.newString(Event.TIMESTAMP));
        RUBY_EVENT_CLASS.setConstant(
            "TIMESTAMP_FAILURE_TAG", RUBY.newString(Event.TIMESTAMP_FAILURE_TAG)
        );
        RUBY_EVENT_CLASS.setConstant(
            "TIMESTAMP_FAILURE_FIELD", RUBY.newString(Event.TIMESTAMP_FAILURE_FIELD)
        );
        RUBY_EVENT_CLASS.setConstant("VERSION", RUBY.newString(Event.VERSION));
        RUBY_EVENT_CLASS.setConstant("VERSION_ONE", RUBY.newString(Event.VERSION_ONE));
        RUBY_EVENT_CLASS.defineAnnotatedMethods(JrubyEventExtLibrary.RubyEvent.class);
        RUBY_EVENT_CLASS.defineAnnotatedConstants(JrubyEventExtLibrary.RubyEvent.class);
        RUBY.getGlobalVariables().set("$LS_JARS_LOADED", RUBY.newString("true"));
    }

    private RubyUtil() {
    }

    /**
     * Wraps a Java exception in a JRuby IOError NativeException.
     * This preserves the Java stacktrace and bubble up as a Ruby IOError
     * @param runtime the Ruby runtime context
     * @param e the Java exception to wrap
     * @return RaiseException the wrapped IOError
     */
    public static RaiseException newRubyIOError(Ruby runtime, Throwable e) {
        // will preserve Java stacktrace & bubble up as a Ruby IOError
        return new RaiseException(e, new NativeException(runtime, runtime.getIOError(), e));
    }

    /**
     * Sets up a Java-defined {@link RubyClass} in the Logstash Ruby module.
     * @param allocator Allocator of the class
     * @param jclass Underlying Java class that is annotated by {@link JRubyClass}
     * @return RubyClass
     */
    private static RubyClass setupLogstashClass(final ObjectAllocator allocator,
        final Class<?> jclass) {
        return setupLogstashClass(RUBY.getObject(), allocator, jclass);
    }

    /**
     * Sets up a Java-defined {@link RubyClass} in the Logstash Ruby module.
     * @param parent Parent RubyClass
     * @param allocator Allocator of the class
     * @param jclass Underlying Java class that is annotated by {@link JRubyClass}
     * @return RubyClass
     */
    private static RubyClass setupLogstashClass(final RubyClass parent,
        final ObjectAllocator allocator, final Class<?> jclass) {
        final RubyClass clazz = RUBY.defineClassUnder(
            jclass.getAnnotation(JRubyClass.class).name()[0], parent, allocator, LOGSTASH_MODULE
        );
        clazz.defineAnnotatedMethods(jclass);
        return clazz;
    }

    @JRubyClass(name = "Error")
    public static final class LogstashRubyError extends RubyException {

        public LogstashRubyError(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }
    }

    @JRubyClass(name = "ParserError")
    public static final class LogstashRubyParserError extends RubyException {

        public LogstashRubyParserError(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }
    }

    @JRubyClass(name = "GeneratorError")
    public static final class LogstashRubyGeneratorError extends RubyException {

        public LogstashRubyGeneratorError(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }
    }

    @JRubyClass(name = "TimestampParserError")
    public static final class LogstashTimestampParserError extends RubyException {

        public LogstashTimestampParserError(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }
    }
}
