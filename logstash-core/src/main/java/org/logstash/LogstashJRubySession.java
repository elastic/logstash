package org.logstash;

import java.nio.file.Path;
import java.nio.file.Paths;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.load.LoadService;
import org.logstash.ackedqueue.ext.AbstractJRubyQueue;
import org.logstash.ackedqueue.ext.RubyAckedBatch;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.ext.JrubyTimestampExtLibrary;

public final class LogstashJRubySession implements AutoCloseable {

    private final Ruby ruby;

    private final RubyModule logstashModule;

    private final RubyClass event;

    private final RubyClass ackedBatch;

    private final RubyClass timestamp;

    private final RubyClass logstashError;

    private final RubyClass parserError;

    private final RubyClass timestampParserError;

    private final RubyClass generatorError;

    public LogstashJRubySession(final Ruby ruby) {
        this.ruby = ruby;
        logstashModule = ruby.getOrCreateModule("LogStash");
        event = setupEvent();
        ackedBatch = setupAckedBatch();
        timestamp = setupLogstashClass(
            JrubyTimestampExtLibrary.RubyTimestamp::new,
            JrubyTimestampExtLibrary.RubyTimestamp.class
        );
        logstashError = setupLogstashStdError(
            RubyUtil.LogstashRubyError::new, RubyUtil.LogstashRubyError.class
        );
        final RubyModule json = logstashModule.defineOrGetModuleUnder("Json");
        parserError = setupClass(
            json, logstashError, RubyUtil.LogstashRubyParserError::new,
            RubyUtil.LogstashRubyParserError.class
        );
        generatorError = setupClass(
            json, logstashError, RubyUtil.LogstashRubyGeneratorError::new,
            RubyUtil.LogstashRubyGeneratorError.class
        );
        timestampParserError = setupLogstashStdError(
            RubyUtil.LogstashTimestampParserError::new, RubyUtil.LogstashTimestampParserError.class
        );
        ensureLoadpath();
    }

    public Ruby getRuby() {
        return ruby;
    }

    public RubyClass getEvent() {
        return event;
    }

    public RubyClass getAckedBatch() {
        return ackedBatch;
    }

    public RubyClass getTimestamp() {
        return timestamp;
    }

    public RubyClass getLogstashError() {
        return logstashError;
    }

    public RubyClass getParserError() {
        return parserError;
    }

    public RubyClass getGeneratorError() {
        return generatorError;
    }

    public RubyClass getTimestampParserError() {
        return timestampParserError;
    }

    public RubyModule getLogstashModule() {
        return logstashModule;
    }

    @Override
    public void close() {
        ruby.tearDown(false);
    }

    /**
     * Sets up the Ruby {@code Event} Class.
     * @return RubyClass for Event
     */
    private RubyClass setupEvent() {
        final RubyClass eventClass = setupLogstashClass(
            JrubyEventExtLibrary.RubyEvent::new, JrubyEventExtLibrary.RubyEvent.class
        );
        defineStringConstant(eventClass, "METADATA", Event.METADATA);
        defineStringConstant(eventClass, "METADATA_BRACKETS", Event.METADATA_BRACKETS);
        defineStringConstant(eventClass, "TIMESTAMP", Event.TIMESTAMP);
        defineStringConstant(eventClass, "TIMESTAMP_FAILURE_TAG", Event.TIMESTAMP_FAILURE_TAG);
        defineStringConstant(
            eventClass, "TIMESTAMP_FAILURE_FIELD", Event.TIMESTAMP_FAILURE_FIELD
        );
        defineStringConstant(eventClass, "VERSION", Event.VERSION);
        defineStringConstant(eventClass, "VERSION_ONE", Event.VERSION_ONE);
        return eventClass;
    }

    /**
     * Sets up the AckedBatch RubyClass including its dependencies.
     * @return AckedBatch RubyClass
     */
    private RubyClass setupAckedBatch() {
        final RubyClass ackedBatch = setupLogstashClass(RubyAckedBatch::new, RubyAckedBatch.class);
        final RubyClass abstractQueue = setupLogstashClass(
            ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR, AbstractJRubyQueue.class
        );
        setupLogstashClass(
            abstractQueue, AbstractJRubyQueue.RubyAckedQueue::new,
            AbstractJRubyQueue.RubyAckedQueue.class
        );
        setupLogstashClass(
            abstractQueue, AbstractJRubyQueue.RubyAckedMemoryQueue::new,
            AbstractJRubyQueue.RubyAckedMemoryQueue.class
        );
        return ackedBatch;
    }

    /**
     * Defines a {@link org.jruby.RubyString String} constant on a {@link RubyClass}.
     * @param clazz RubyClass
     * @param name Name of the Constant
     * @param value Value of the Constant
     */
    private void defineStringConstant(final RubyClass clazz, final String name,
        final String value) {
        clazz.setConstant(name, ruby.newString(value));
    }

    /**
     * Sets up a Java-defined {@link RubyClass} in the Logstash Ruby module.
     * @param allocator Allocator of the class
     * @param jclass Underlying Java class that is annotated by {@link JRubyClass}
     * @return RubyClass
     */
    private RubyClass setupLogstashClass(final ObjectAllocator allocator,
        final Class<?> jclass) {
        return setupLogstashClass(ruby.getObject(), allocator, jclass);
    }

    /**
     * Sets up a Java-defined {@link RubyClass} as a subclass of {@link Ruby#standardError}
     * in the Logstash Ruby module.
     * @param allocator Allocator of the class
     * @param jclass Underlying Java class that is annotated by {@link JRubyClass}
     * @return RubyClass
     */
    private RubyClass setupLogstashStdError(final ObjectAllocator allocator,
        final Class<?> jclass) {
        return setupClass(logstashModule, ruby.getStandardError(), allocator, jclass);
    }

    /**
     * Sets up a Java-defined {@link RubyClass} in the Logstash Ruby module.
     * @param parent Parent RubyClass
     * @param allocator Allocator of the class
     * @param jclass Underlying Java class that is annotated by {@link JRubyClass}
     * @return RubyClass
     */
    private RubyClass setupLogstashClass(final RubyClass parent,
        final ObjectAllocator allocator, final Class<?> jclass) {
        return setupClass(logstashModule, parent, allocator, jclass);
    }

    /**
     * Sets up a Java-defined {@link RubyClass}.
     * @param module RubyModule to define class under
     * @param parent Parent RubyClass
     * @param allocator Allocator of the class
     * @param jclass Underlying Java class that is annotated by {@link JRubyClass}
     * @return RubyClass
     */
    private RubyClass setupClass(final RubyModule module, final RubyClass parent,
        final ObjectAllocator allocator, final Class<?> jclass) {
        final RubyClass clazz = ruby.defineClassUnder(
            jclass.getAnnotation(JRubyClass.class).name()[0], parent, allocator, module
        );
        clazz.defineAnnotatedMethods(jclass);
        clazz.defineAnnotatedConstants(jclass);
        return clazz;
    }

    /**
     * Loads the logstash-core/lib path if the load service can't find {@code logstash/compiler}.
     */
    private void ensureLoadpath() {
        final LoadService loader = ruby.getLoadService();
        if (loader.findFileForLoad("logstash/compiler").library == null) {
            final RubyHash environment = ruby.getENV();
            final Path root = Paths.get(
                System.getProperty("logstash.core.root.dir", "")
            ).toAbsolutePath();
            final String gems = root.getParent().resolve("vendor").resolve("bundle")
                .resolve("jruby").resolve("2.3.0").toFile().getAbsolutePath();
            environment.put("GEM_HOME", gems);
            environment.put("GEM_PATH", gems);
            loader.addPaths(root.resolve("lib").toFile().getAbsolutePath()
            );
        }
    }
}
