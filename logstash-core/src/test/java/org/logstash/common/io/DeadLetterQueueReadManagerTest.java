package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.ackedqueue.StringElement;

import java.nio.file.Path;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;

public class DeadLetterQueueReadManagerTest {
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void testReadFromTwoSegments() throws Exception {
        RecordIOWriter writer = null;

        for (int i = 0; i < 5; i++) {
            Path segmentPath = dir.resolve(String.format(DeadLetterQueueWriteManager.SEGMENT_FILE_PATTERN, i));
            writer = new RecordIOWriter(segmentPath);
            for (int j = 0; j < 10; j++) {
                writer.writeRecord((new StringElement("" + (i * 10 + j))).serialize());
            }
            if (i < 4) {
                writer.close();
            }
        }

        DeadLetterQueueReadManager manager = new DeadLetterQueueReadManager(dir);

        for (int i = 0; i < 50; i++) {
            String first = StringElement.deserialize(manager.pollRecord()).toString();
            assertThat(first, equalTo(String.valueOf(i)));
        }

        assertThat(manager.pollRecord(), is(nullValue()));
        assertThat(manager.pollRecord(), is(nullValue()));
        assertThat(manager.pollRecord(), is(nullValue()));
        assertThat(manager.pollRecord(), is(nullValue()));

        for (int j = 50; j < 60; j++) {
            writer.writeRecord((new StringElement(String.valueOf(j))).serialize());
        }

        for (int i = 50; i < 60; i++) {
            String first = StringElement.deserialize(manager.pollRecord()).toString();
            assertThat(first, equalTo(String.valueOf(i)));
        }

        writer.close();

        Path segmentPath = dir.resolve(String.format(DeadLetterQueueWriteManager.SEGMENT_FILE_PATTERN, 5));
        writer = new RecordIOWriter(segmentPath);

        for (int j = 0; j < 10; j++) {
            writer.writeRecord((new StringElement(String.valueOf(j))).serialize());
        }


        for (int i = 0; i < 10; i++) {
            byte[] read = manager.pollRecord();
            while (read == null) {
                read = manager.pollRecord();
            }
            String first = StringElement.deserialize(read).toString();
            assertThat(first, equalTo(String.valueOf(i)));
        }


        manager.close();
    }
}