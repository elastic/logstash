/*
 * Licensed to Elasticsearch under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.common.io;

import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.DLQEntry;
import org.logstash.Event;

import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.OverlappingFileLockException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

import static junit.framework.TestCase.assertFalse;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION_SIZE;

public class DeadLetterQueueWriterTest {
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    private static long EMPTY_DLQ = VERSION_SIZE; // Only the version field has been written

    @Test
    public void testLockFileManagement() throws Exception {
        Path lockFile = dir.resolve(".lock");
        DeadLetterQueueWriter writer = new DeadLetterQueueWriter(dir, 1000, 1000000);
        assertTrue(Files.exists(lockFile));
        writer.close();
        assertFalse(Files.exists(lockFile));
    }

    @Test
    public void testFileLocking() throws Exception {
        DeadLetterQueueWriter writer = new DeadLetterQueueWriter(dir, 1000, 1000000);
        try {
            new DeadLetterQueueWriter(dir, 1000, 100000);
            fail();
        } catch (RuntimeException e) {
        } finally {
            writer.close();
        }
    }

    @Test
    public void testUncleanCloseOfPreviousWriter() throws Exception {
        Path lockFilePath = dir.resolve(".lock");
        boolean created = lockFilePath.toFile().createNewFile();
        DeadLetterQueueWriter writer = new DeadLetterQueueWriter(dir, 1000, 1000000);

        FileChannel channel = FileChannel.open(lockFilePath, StandardOpenOption.WRITE);
        try {
            channel.lock();
            fail();
        } catch (OverlappingFileLockException e) {
            assertTrue(created);
        } finally {
            writer.close();
        }
    }

    @Test
    public void testWrite() throws Exception {
        DeadLetterQueueWriter writer = new DeadLetterQueueWriter(dir, 1000, 1000000);
        DLQEntry entry = new DLQEntry(new Event(), "type", "id", "reason");
        writer.writeEntry(entry);
        writer.close();
    }

    @Test
    public void testDoesNotWriteMessagesAlreadyRoutedThroughDLQ() throws Exception {
        Event dlqEvent = new Event();
        dlqEvent.setField("[@metadata][dead_letter_queue][plugin_type]", "dead_letter_queue");
        DLQEntry entry = new DLQEntry(new Event(), "type", "id", "reason");
        DLQEntry dlqEntry = new DLQEntry(dlqEvent, "type", "id", "reason");

        try (DeadLetterQueueWriter writer = new DeadLetterQueueWriter(dir, 1000, 1000000);) {
            writer.writeEntry(entry);
            long dlqLengthAfterEvent  = dlqLength();

            assertThat(dlqLengthAfterEvent, is(not(EMPTY_DLQ)));
            writer.writeEntry(dlqEntry);
            assertThat(dlqLength(), is(dlqLengthAfterEvent));
        }
    }

    @Test
    public void testDoesNotWriteBeyondLimit() throws Exception {
        DLQEntry entry = new DLQEntry(new Event(), "type", "id", "reason");

        int payloadLength = RECORD_HEADER_SIZE + VERSION_SIZE + entry.serialize().length;
        final int MESSAGE_COUNT= 5;
        long MAX_QUEUE_LENGTH = payloadLength * MESSAGE_COUNT;
        DeadLetterQueueWriter writer = null;

        try{
            writer = new DeadLetterQueueWriter(dir, payloadLength, MAX_QUEUE_LENGTH);
            for (int i = 0; i < MESSAGE_COUNT; i++)
                writer.writeEntry(entry);

            assertThat(dlqLength(), is(MAX_QUEUE_LENGTH));
            writer.writeEntry(entry);
            assertThat(dlqLength(), is(MAX_QUEUE_LENGTH));
        } finally {
            if (writer != null) {
                writer.close();
            }
        }
    }

    private long dlqLength() throws IOException {
        return Files.list(dir)
                .filter(p -> p.toString().endsWith(".log"))
                .mapToLong(p -> p.toFile().length())
                .sum();
    }
}