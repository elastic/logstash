package org.logstash;

import org.jruby.NativeException;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyException;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ObjectAllocator;
import org.logstash.ackedqueue.ext.AbstractJRubyQueue;
import org.logstash.ackedqueue.ext.RubyAckedBatch;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.ext.JrubyTimestampExtLibrary;

/**
 * Utilities around interaction with the {@link Ruby} runtime.
 */
public final class RubyUtil {

    /**
     * Reference to the global {@link Ruby} runtime.
     */
    public static final Ruby RUBY;

    /**
     * Logstash Ruby Module.
     */
    public static final RubyModule LOGSTASH_MODULE;

    public static final RubyClass RUBY_EVENT_CLASS;

    public static final RubyClass RUBY_ACKED_BATCH_CLASS;

    public static final RubyClass RUBY_TIMESTAMP_CLASS;

    public static final RubyClass PARSER_ERROR;

    public static final RubyClass GENERATOR_ERROR;

    public static final RubyClass LOGSTASH_ERROR;

    public static final RubyClass TIMESTAMP_PARSER_ERROR;

    static {
        RUBY = Ruby.getGlobalRuntime();
        LOGSTASH_MODULE = RUBY.getOrCreateModule("LogStash");
        RUBY_TIMESTAMP_CLASS = setupLogstashClass(
            JrubyTimestampExtLibrary.RubyTimestamp::new,
            JrubyTimestampExtLibrary.RubyTimestamp.class
        );
        RUBY_EVENT_CLASS = setupLogstashClass(
            JrubyEventExtLibrary.RubyEvent::new, JrubyEventExtLibrary.RubyEvent.class
        );
        defineStringConstant(RUBY_EVENT_CLASS, "METADATA", Event.METADATA);
        defineStringConstant(RUBY_EVENT_CLASS, "METADATA_BRACKETS", Event.METADATA_BRACKETS);
        defineStringConstant(RUBY_EVENT_CLASS, "TIMESTAMP", Event.TIMESTAMP);
        defineStringConstant(
            RUBY_EVENT_CLASS, "TIMESTAMP_FAILURE_TAG", Event.TIMESTAMP_FAILURE_TAG
        );
        defineStringConstant(
            RUBY_EVENT_CLASS, "TIMESTAMP_FAILURE_FIELD", Event.TIMESTAMP_FAILURE_FIELD
        );
        defineStringConstant(RUBY_EVENT_CLASS, "VERSION", Event.VERSION);
        defineStringConstant(RUBY_EVENT_CLASS, "VERSION_ONE", Event.VERSION_ONE);
        final RubyModule json = LOGSTASH_MODULE.defineOrGetModuleUnder("Json");
        final RubyClass stdErr = RUBY.getStandardError();
        LOGSTASH_ERROR = setupLogstashClass(
            stdErr, RubyUtil.LogstashRubyError::new, RubyUtil.LogstashRubyError.class
        );
        PARSER_ERROR = setupClass(
            json, LOGSTASH_ERROR, RubyUtil.LogstashRubyParserError::new,
            RubyUtil.LogstashRubyParserError.class
        );
        TIMESTAMP_PARSER_ERROR = setupLogstashClass(
            stdErr, RubyUtil.LogstashTimestampParserError::new,
            RubyUtil.LogstashTimestampParserError.class
        );
        GENERATOR_ERROR = setupClass(
            json, LOGSTASH_ERROR, RubyUtil.LogstashRubyGeneratorError::new,
            RubyUtil.LogstashRubyGeneratorError.class
        );
        final RubyClass abstractQueue = setupLogstashClass(
            ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, AbstractJRubyQueue.class
        );
        RUBY_ACKED_BATCH_CLASS = setupLogstashClass(RubyAckedBatch::new, RubyAckedBatch.class);
        setupLogstashClass(
            abstractQueue, AbstractJRubyQueue.RubyAckedQueue::new,
            AbstractJRubyQueue.RubyAckedQueue.class
        );
        setupLogstashClass(
            abstractQueue, AbstractJRubyQueue.RubyAckedMemoryQueue::new,
            AbstractJRubyQueue.RubyAckedMemoryQueue.class
        );
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

    private static void defineStringConstant(final RubyClass clazz, final String name,
        final String value) {
        clazz.setConstant(name, RUBY.newString(value));
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
        return setupClass(LOGSTASH_MODULE, parent, allocator, jclass);
    }

    /**
     * Sets up a Java-defined {@link RubyClass}.
     * @param module RubyModule to define class under
     * @param parent Parent RubyClass
     * @param allocator Allocator of the class
     * @param jclass Underlying Java class that is annotated by {@link JRubyClass}
     * @return RubyClass
     */
    private static RubyClass setupClass(final RubyModule module, final RubyClass parent,
        final ObjectAllocator allocator, final Class<?> jclass) {
        final RubyClass clazz = RUBY.defineClassUnder(
            jclass.getAnnotation(JRubyClass.class).name()[0], parent, allocator, module
        );
        clazz.defineAnnotatedMethods(jclass);
        clazz.defineAnnotatedConstants(jclass);
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
