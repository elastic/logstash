package org.logstash.common;

import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.DLQEntry;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;
import org.logstash.common.io.DeadLetterQueueReader;
import org.logstash.common.io.DeadLetterQueueWriter;
import org.logstash.common.io.QueueStorageType;
import org.logstash.ext.JrubyEventExtLibrary;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Duration;

public class AbstractDeadLetterQueueWriterExtTest extends RubyTestBase {

    static final int DLQ_VERSION_SIZE = 1;

    @Rule
    public TemporaryFolder tmpFolder = new TemporaryFolder();

    @Test
    public void testDLQWriterDoesntInvertPluginIdAndPluginTypeAttributes() throws IOException, InterruptedException {
        final Path dlqPath = tmpFolder.newFolder("dead_letter_queue").toPath();
        final String pluginId = "id_value";
        final String pluginType = "elasticsearch";
        final String dlqName = "main";

        writeAnEventIntoDLQ(dlqPath, pluginId, pluginType, dlqName);

        String segment = "1.log";
        DeadLetterQueueReader dlqReader = openDeadLetterQueueReader(dlqPath, dlqName, segment);

        DLQEntry dlqEntry = dlqReader.pollEntry(1_000);
        assertNotNull("A DLQEntry must be present in the queue", dlqEntry);
        assertEquals(pluginId, dlqEntry.getPluginId());
        assertEquals(pluginType, dlqEntry.getPluginType());
    }

    private DeadLetterQueueReader openDeadLetterQueueReader(Path dlqPath, String dlqName, String segment) throws IOException {
        DeadLetterQueueReader dlqReader = new DeadLetterQueueReader(dlqPath);
        Path currentSegmentFile = dlqPath.resolve(dlqName).resolve(segment);
        dlqReader.setCurrentReaderAndPosition(currentSegmentFile, DLQ_VERSION_SIZE);
        assertEquals(currentSegmentFile, dlqReader.getCurrentSegment());
        return dlqReader;
    }

    private void writeAnEventIntoDLQ(Path dlqPath, String pluginId, String pluginType, String dlqName) {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        RubyString id = RubyString.newString(RubyUtil.RUBY, pluginId);
        RubyString classConfigName = RubyString.newString(RubyUtil.RUBY, pluginType);

        final DeadLetterQueueWriter javaDlqWriter = DeadLetterQueueFactory.getWriter(dlqName, dlqPath.toString(), 1024 * 1024, Duration.ofHours(1), QueueStorageType.DROP_NEWER);
        IRubyObject dlqWriter = JavaUtil.convertJavaToUsableRubyObject(context.runtime, javaDlqWriter);

        final AbstractDeadLetterQueueWriterExt dlqWriterForInstance = new AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt(
                RubyUtil.RUBY, RubyUtil.PLUGIN_DLQ_WRITER_CLASS
        ).initialize(context, dlqWriter, id, classConfigName);

        // create a Logstash event to store into DLQ
        JrubyEventExtLibrary.RubyEvent event = JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY);
        event.getEvent().setField("name", "John");

        dlqWriterForInstance.doWrite(context, event, RubyString.newString(RubyUtil.RUBY, "A reason to DLQ-ing"));

        dlqWriterForInstance.close(context);
    }

}