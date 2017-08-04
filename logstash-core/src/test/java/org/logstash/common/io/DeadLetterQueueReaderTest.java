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
import org.logstash.Timestamp;
import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Collections;
import java.util.Random;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;

public class DeadLetterQueueReaderTest {
    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    private static String segmentFileName(int i) {
        return String.format(DeadLetterQueueWriter.SEGMENT_FILE_PATTERN, i);
    }

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
    }

    @Test
    public void testReadFromTwoSegments() throws Exception {
        RecordIOWriter writer = null;

        for (int i = 0; i < 5; i++) {
            Path segmentPath = dir.resolve(segmentFileName(i));
            writer = new RecordIOWriter(segmentPath);
            for (int j = 0; j < 10; j++) {
                writer.writeEvent((new StringElement("" + (i * 10 + j))).serialize());
            }
            if (i < 4) {
                writer.close();
            }
        }

        DeadLetterQueueReader manager = new DeadLetterQueueReader(dir);

        for (int i = 0; i < 50; i++) {
            String first = StringElement.deserialize(manager.pollEntryBytes()).toString();
            assertThat(first, equalTo(String.valueOf(i)));
        }

        assertThat(manager.pollEntryBytes(), is(nullValue()));
        assertThat(manager.pollEntryBytes(), is(nullValue()));
        assertThat(manager.pollEntryBytes(), is(nullValue()));
        assertThat(manager.pollEntryBytes(), is(nullValue()));

        for (int j = 50; j < 60; j++) {
            writer.writeEvent((new StringElement(String.valueOf(j))).serialize());
        }

        for (int i = 50; i < 60; i++) {
            String first = StringElement.deserialize(manager.pollEntryBytes()).toString();
            assertThat(first, equalTo(String.valueOf(i)));
        }

        writer.close();

        Path segmentPath = dir.resolve(segmentFileName(5));
        writer = new RecordIOWriter(segmentPath);

        for (int j = 0; j < 10; j++) {
            writer.writeEvent((new StringElement(String.valueOf(j))).serialize());
        }


        for (int i = 0; i < 10; i++) {
            byte[] read = manager.pollEntryBytes();
            while (read == null) {
                read = manager.pollEntryBytes();
            }
            String first = StringElement.deserialize(read).toString();
            assertThat(first, equalTo(String.valueOf(i)));
        }


        manager.close();
    }


    // This test checks that polling after a block has been mostly filled with an event is handled correctly.
    @Test
    public void testRereadFinalBlock() throws Exception {
        Event event = new Event(Collections.emptyMap());

        // Fill event with not quite enough characters to fill block. Fill event with valid RecordType characters - this
        // was the cause of https://github.com/elastic/logstash/issues/7868
        char[] field = new char[32500];
        Arrays.fill(field, 's');
        event.setField("message", new String(field));
        long startTime = System.currentTimeMillis();
        int messageSize = 0;
        DeadLetterQueueWriter writeManager = null;
        try {
            writeManager = new DeadLetterQueueWriter(dir, 10 * 1024 * 1024, 1_000_000_000);
            for (int i = 0; i < 2; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", "", new Timestamp(startTime++));
                messageSize += entry.serialize().length;
                writeManager.writeEntry(entry);
            }
        } finally {
            if (writeManager != null) writeManager.close();
        }
        DeadLetterQueueReader readManager = null;
        try {
            readManager = new DeadLetterQueueReader(dir);
            for (int i = 0; i < 3;i++) {
                readManager.pollEntry(100);
            }
        } finally {
            if (readManager != null) readManager.close();
        }
    }


    @Test
    public void testSeek() throws Exception {
        Event event = new Event(Collections.emptyMap());
        long currentEpoch = System.currentTimeMillis();
        int TARGET_EVENT = 543;

        writeEntries(event, 0, 1000, currentEpoch);
        seekReadAndVerify(new Timestamp(currentEpoch + TARGET_EVENT),
                          String.valueOf(TARGET_EVENT));
    }


    // Notes on these tests:
    //   These tests are designed to test specific edge cases where events end at block boundaries, hence the specific
    //    sizes of the char arrays being used to pad the events

    // This test tests for a single event that ends on a block boundary
    @Test
    public void testBlockBoundary() throws Exception {

        final int PAD_FOR_BLOCK_SIZE_EVENT = 32616;
        Event event = new Event();
        char[] field = new char[PAD_FOR_BLOCK_SIZE_EVENT];
        Arrays.fill(field, 'e');
        event.setField("T", new String(field));
        Timestamp timestamp = new Timestamp();

        DeadLetterQueueWriter writeManager = null;
        try {
            writeManager = new DeadLetterQueueWriter(dir, 10 * 1024 * 1024, 1_000_000_000);
            for (int i = 0; i < 2; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", "", timestamp);
                assertThat(entry.serialize().length + RecordIOWriter.RECORD_HEADER_SIZE, is(BLOCK_SIZE));
                writeManager.writeEntry(entry);
            }
        } finally {
            writeManager.close();
        }
        DeadLetterQueueReader readManager = null;
        try  {
            readManager = new DeadLetterQueueReader(dir);
            for (int i = 0; i < 2;i++) {
                readManager.pollEntry(100);
            }
        } finally {
            readManager.close();
        }
    }

    // This test has multiple messages, with a message ending on a block boundary
    @Test
    public void testBlockBoundaryMultiple() throws Exception {
        Event event = new Event(Collections.emptyMap());
        char[] field = new char[8053];
        Arrays.fill(field, 'x');
        event.setField("message", new String(field));
        long startTime = System.currentTimeMillis();
        int messageSize = 0;
        DeadLetterQueueWriter writeManager = null;
        try {
            writeManager = new DeadLetterQueueWriter(dir, 10 * 1024 * 1024, 1_000_000_000);
            for (int i = 1; i <= 5; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", "", new Timestamp(startTime++));
                messageSize += entry.serialize().length;
                writeManager.writeEntry(entry);
                if (i == 4){
                    assertThat(messageSize + (RecordIOWriter.RECORD_HEADER_SIZE * 4), is(BLOCK_SIZE));
                }
            }
        }finally{
            if (writeManager != null) writeManager.close();
        }
        DeadLetterQueueReader readManager = null;
        try {
            readManager = new DeadLetterQueueReader(dir);
            for (int i = 0; i < 5;i++) {
                readManager.pollEntry(100);
            }
        }finally{
            if (readManager != null) readManager.close();
        }
    }


    // This test tests for a single event that ends on a block and segment boundary
    @Test
    public void testBlockAndSegmentBoundary() throws Exception {
        final int PAD_FOR_BLOCK_SIZE_EVENT = 32616;
        Event event = new Event();
        char[] field = new char[PAD_FOR_BLOCK_SIZE_EVENT];
        Arrays.fill(field, 'e');
        event.setField("T", new String(field));
        Timestamp timestamp = new Timestamp();

        DeadLetterQueueWriter writeManager = null;
        try {
            writeManager = new DeadLetterQueueWriter(dir, BLOCK_SIZE, 1_000_000_000);
            for (int i = 0; i < 2; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", "", timestamp);
                assertThat(entry.serialize().length + RecordIOWriter.RECORD_HEADER_SIZE, is(BLOCK_SIZE));
                writeManager.writeEntry(entry);
            }
        } finally {
            if (writeManager != null) writeManager.close();
        }
        DeadLetterQueueReader readManager = null;
        try {
            readManager = new DeadLetterQueueReader(dir);
            for (int i = 0; i < 2;i++) {
                readManager.pollEntry(100);
            }
        }
        finally{
            if (readManager != null) readManager.close();
        }
    }


    @Test
    public void testWriteReadRandomEventSize() throws Exception {
        Event event = new Event(Collections.emptyMap());
        int eventCount = 3000;
        int maxEventSize = BLOCK_SIZE * 2;
        long startTime = System.currentTimeMillis();

        DeadLetterQueueWriter writeManager = null;
        try {
            writeManager = new DeadLetterQueueWriter(dir, 10 * 1024 * 1024, 1_000_000_000L);
            for (int i = 0; i < eventCount; i++) {
                char[] field = new char[(int)(Math.random() * (maxEventSize))];
                Arrays.fill(field, randomFillItem());
                event.setField("message", new String(field));
                DLQEntry entry = new DLQEntry(event, "", "", String.valueOf(i), new Timestamp(startTime++));
                writeManager.writeEntry(entry);
            }
        }finally{
            if (writeManager != null) writeManager.close();
        }

        DeadLetterQueueReader readManager = null;
        try {
            readManager = new DeadLetterQueueReader(dir);
            for (int i = 0; i < eventCount;i++) {
                DLQEntry entry = readManager.pollEntry(100);
                assertThat(entry.getReason(), is(String.valueOf(i)));
            }
        } finally {
            if (readManager != null) readManager.close();
        }
    }

    // Select a random char to fill the list with.
    // Randomly selects a valid value for RecordType, or a non-valid value.
    private char randomFillItem() {
        char[] valid = new char[RecordType.values().length + 1];
        int j = 0;
        valid[j] = 'x';
        for (RecordType type : RecordType.values()){
            valid[j++] = (char)type.toByte();
        }
        Random random = new Random();
        return valid[random.nextInt(valid.length)];
    }

    @Test
    public void testWriteStopSmallWriteSeekByTimestamp() throws Exception {
        int FIRST_WRITE_EVENT_COUNT = 100;
        int SECOND_WRITE_EVENT_COUNT = 100;
        int OFFSET = 200;

        Event event = new Event(Collections.emptyMap());
        long startTime = System.currentTimeMillis();

        writeEntries(event, 0, FIRST_WRITE_EVENT_COUNT, startTime);
        writeEntries(event, OFFSET, SECOND_WRITE_EVENT_COUNT, startTime + 1_000);

        seekReadAndVerify(new Timestamp(startTime + FIRST_WRITE_EVENT_COUNT),
                          String.valueOf(FIRST_WRITE_EVENT_COUNT));
    }

    @Test
    public void testWriteStopBigWriteSeekByTimestamp() throws Exception {
        int FIRST_WRITE_EVENT_COUNT = 100;
        int SECOND_WRITE_EVENT_COUNT = 2000;
        int OFFSET = 200;

        Event event = new Event(Collections.emptyMap());
        long startTime = System.currentTimeMillis();

        writeEntries(event, 0, FIRST_WRITE_EVENT_COUNT, startTime);
        writeEntries(event, OFFSET, SECOND_WRITE_EVENT_COUNT, startTime + 1_000);

        seekReadAndVerify(new Timestamp(startTime + FIRST_WRITE_EVENT_COUNT),
                          String.valueOf(FIRST_WRITE_EVENT_COUNT));
    }

    private void seekReadAndVerify(final Timestamp seekTarget, final String expectedValue) throws Exception {
        DeadLetterQueueReader readManager = null;
        try {
            readManager = new DeadLetterQueueReader(dir);
            readManager.seekToNextEvent(new Timestamp(seekTarget));
            DLQEntry readEntry = readManager.pollEntry(100);
            assertThat(readEntry.getReason(), equalTo(expectedValue));
            assertThat(readEntry.getEntryTime().toIso8601(), equalTo(seekTarget.toIso8601()));
        }finally {
            if (readManager != null) {
                readManager.close();
            }
        }
    }

    private void writeEntries(final Event event, int offset, final int numberOfEvents, long startTime) throws IOException {
        DeadLetterQueueWriter writeManager = null;
        try {
            writeManager = new DeadLetterQueueWriter(dir, 10000000, 10000000);
            for (int i = offset; i <= offset + numberOfEvents; i++) {
                DLQEntry entry = new DLQEntry(event, "foo", "bar", String.valueOf(i), new Timestamp(startTime++));
                writeManager.writeEntry(entry);
            }
        } finally {
            if (writeManager != null) {
                writeManager.close();
            }
        }
    }

    @Test
    public void testInvalidDirectory()  throws Exception {
        DeadLetterQueueReader reader = new DeadLetterQueueReader(dir);
        assertThat(reader.pollEntry(100), is(nullValue()));
    }
}
