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

import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.OverlappingFileLockException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.time.Duration;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.hamcrest.CoreMatchers;
import org.hamcrest.Matchers;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.DLQEntry;
import org.logstash.Event;
import org.logstash.LockException;
import org.logstash.Timestamp;

import static junit.framework.TestCase.assertFalse;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.greaterThan;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.logstash.common.io.DeadLetterQueueTestUtils.FULL_SEGMENT_FILE_SIZE;
import static org.logstash.common.io.DeadLetterQueueTestUtils.MB;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
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
        DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 100_000, Duration.ofSeconds(1))
                .build();
        assertTrue(Files.exists(lockFile));
        writer.close();
        assertFalse(Files.exists(lockFile));
    }

    @Test
    public void testFileLocking() throws Exception {
        DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 100_000, Duration.ofSeconds(1))
                .build();
        try {
            DeadLetterQueueWriter
                    .newBuilder(dir, 100, 1_000, Duration.ofSeconds(1))
                    .build();
            fail();
        } catch (LockException e) {
        } finally {
            writer.close();
        }
    }

    @Test
    public void testUncleanCloseOfPreviousWriter() throws Exception {
        Path lockFilePath = dir.resolve(".lock");
        boolean created = lockFilePath.toFile().createNewFile();
        DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 100_000, Duration.ofSeconds(1))
                .build();

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
        DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 100_000, Duration.ofSeconds(1))
                .build();
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

        try (DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 100_000, Duration.ofSeconds(1))
                .build()) {
            writer.writeEntry(entry);
            long dlqLengthAfterEvent = dlqLength();

            assertThat(dlqLengthAfterEvent, is(not(EMPTY_DLQ)));
            writer.writeEntry(dlqEntry);
            assertThat(dlqLength(), is(dlqLengthAfterEvent));
        }
    }

    @Test
    public void testDoesNotWriteBeyondLimit() throws Exception {
        DLQEntry entry = new DLQEntry(new Event(), "type", "id", "reason");

        int payloadLength = RECORD_HEADER_SIZE + VERSION_SIZE + entry.serialize().length;
        final int MESSAGE_COUNT = 5;
        long MAX_QUEUE_LENGTH = payloadLength * MESSAGE_COUNT;


        try (DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, payloadLength, MAX_QUEUE_LENGTH, Duration.ofSeconds(1))
                .build()) {

            for (int i = 0; i < MESSAGE_COUNT; i++)
                writer.writeEntry(entry);

            // Sleep to allow flush to happen
            sleep(3000);
            assertThat(dlqLength(), is(MAX_QUEUE_LENGTH));
            writer.writeEntry(entry);
            sleep(2000);
            assertThat(dlqLength(), is(MAX_QUEUE_LENGTH));
        }
    }

    @Test
    public void testSlowFlush() throws Exception {
        try (DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 1_000_000, Duration.ofSeconds(1))
                .build()) {
            DLQEntry entry = new DLQEntry(new Event(), "type", "id", "1");
            writer.writeEntry(entry);
            entry = new DLQEntry(new Event(), "type", "id", "2");
            // Sleep to allow flush to happen\
            sleep(3000);
            writer.writeEntry(entry);
            sleep(2000);
            // Do not close here - make sure that the slow write is processed

            try (DeadLetterQueueReader reader = new DeadLetterQueueReader(dir)) {
                assertThat(reader.pollEntry(100).getReason(), is("1"));
                assertThat(reader.pollEntry(100).getReason(), is("2"));
            }
        }
    }


    @Test
    public void testNotFlushed() throws Exception {
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, BLOCK_SIZE, 1_000_000_000, Duration.ofSeconds(5))
                .build()) {
            for (int i = 0; i < 4; i++) {
                DLQEntry entry = new DLQEntry(new Event(), "type", "id", "1");
                writeManager.writeEntry(entry);
            }

            // Allow for time for scheduled flush check
            Thread.sleep(1000);

            try (DeadLetterQueueReader readManager = new DeadLetterQueueReader(dir)) {
                for (int i = 0; i < 4; i++) {
                    DLQEntry entry = readManager.pollEntry(100);
                    assertThat(entry, is(CoreMatchers.nullValue()));
                }
            }
        }
    }


    @Test
    public void testCloseFlush() throws Exception {
        try (DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 1_000_000, Duration.ofHours(1))
                .build()) {
            DLQEntry entry = new DLQEntry(new Event(), "type", "id", "1");
            writer.writeEntry(entry);
        }
        try (DeadLetterQueueReader reader = new DeadLetterQueueReader(dir)) {
            assertThat(reader.pollEntry(100).getReason(), is("1"));
        }
    }

    private void sleep(long millis) throws InterruptedException {
        Thread.sleep(millis);
        Thread.yield();
    }

    private long dlqLength() throws IOException {
        try (final Stream<Path> files = Files.list(dir)) {
            return files.filter(p -> p.toString().endsWith(".log"))
                .mapToLong(p -> p.toFile().length()).sum();
        }
    }

    static String generateASCIIMessageContent(int size, byte fillChar) {
        byte[] fillArray = new byte[size];
        Arrays.fill(fillArray, fillChar);
        return new String(fillArray);
    }

    @Test
    public void testRemoveOldestSegmentWhenRetainedSizeIsExceededAndDropOlderModeIsEnabled() throws IOException {
        Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(Collections.emptyMap());
        event.setField("message", DeadLetterQueueReaderTest.generateMessageContent(32479));
        long startTime = System.currentTimeMillis();

        int messageSize = 0;
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 20 * MB, Duration.ofSeconds(1))
                .build()) {

            // 320 generates 10 Mb of data
            for (int i = 0; i < (320 * 2) - 1; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", i), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(startTime));
                final int serializationLength = entry.serialize().length;
                assertEquals("Serialized entry fills block payload", BLOCK_SIZE - RECORD_HEADER_SIZE, serializationLength);
                messageSize += serializationLength;
                writeManager.writeEntry(entry);
            }
            assertThat(messageSize, Matchers.is(greaterThan(BLOCK_SIZE)));
        }

        // but every segment file has 1 byte header, 639 messages of 32Kb generates 3 files
        // 0.log with 319
        // 1.log with 319
        // 2.log with 1
        List<String> segmentFileNames = Files.list(dir)
                .map(Path::getFileName)
                .map(Path::toString)
                .sorted()
                .collect(Collectors.toList());
        assertEquals(3, segmentFileNames.size());
        final String fileToBeRemoved = segmentFileNames.get(0);

        // Exercise
        // with another 32Kb message write we go to write the third file and trigger the 20Mb limit of retained store
        final long prevQueueSize;
        final long beheadedQueueSize;
        long droppedEvent;
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 20 * MB, Duration.ofSeconds(1))
                .storageType(QueueStorageType.DROP_OLDER)
                .build()) {
            prevQueueSize = writeManager.getCurrentQueueSize();
            final int expectedQueueSize = 2 * // number of full segment files
                    FULL_SEGMENT_FILE_SIZE  + // size of a segment file
                    VERSION_SIZE + BLOCK_SIZE + // the third segment file with just one message
                    VERSION_SIZE; // the header of the head tmp file created in opening
            assertEquals("Queue size is composed of 2 full segment files plus one with an event plus another with just the header byte",
                    expectedQueueSize, prevQueueSize);
            DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", (320 * 2) - 1), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(startTime));
            writeManager.writeEntry(entry);
            beheadedQueueSize = writeManager.getCurrentQueueSize();
            droppedEvent = writeManager.getDroppedEvents();
        }

        // 1.log with 319
        // 2.log with 1
        // 3.log with 1, created because the close flushes and beheaded the tail file.
        Set<String> afterBeheadSegmentFileNames = Files.list(dir)
                .map(Path::getFileName)
                .map(Path::toString)
                .collect(Collectors.toSet());
        assertEquals(3, afterBeheadSegmentFileNames.size());
        assertThat(afterBeheadSegmentFileNames, Matchers.not(Matchers.contains(fileToBeRemoved)));
        final long expectedQueueSize = prevQueueSize +
                BLOCK_SIZE - // the space of the newly inserted message
                FULL_SEGMENT_FILE_SIZE - //the size of the removed segment file
                VERSION_SIZE; // the size of a previous head file (n.log.tmp) that doesn't exist anymore.
        assertEquals("Total queue size must be decremented by the size of the first segment file",
                expectedQueueSize, beheadedQueueSize);
        assertEquals("Last segment removal doesn't increment dropped events counter",
                0, droppedEvent);
    }

    @Test
    public void testRemoveSegmentsOrder() throws IOException {
        try (DeadLetterQueueWriter sut = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 20 * MB, Duration.ofSeconds(1))
                .build()) {
            // create some segments files
            Files.createFile(dir.resolve("9.log"));
            Files.createFile(dir.resolve("10.log"));

            // Exercise
            sut.dropTailSegment();

            // Verify
            final Set<String> segments = Files.list(dir)
                    .map(Path::getFileName)
                    .map(Path::toString)
                    .filter(s -> !s.endsWith(".tmp")) // skip current writer head file 1.log.tmp
                    .filter(s -> !".lock".equals(s)) // skip .lock file created by writer
                    .collect(Collectors.toSet());
            assertEquals(Collections.singleton("10.log"), segments);
        }
    }

    @Test
    public void testUpdateOldestSegmentReference() throws IOException {
        try (DeadLetterQueueWriter sut = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 20 * MB)
                .build()) {

            final byte[] eventBytes = new DLQEntry(new Event(), "", "", "").serialize();

            try(RecordIOWriter writer = new RecordIOWriter(dir.resolve("1.log"))){
                writer.writeEvent(eventBytes);
            }

            try(RecordIOWriter writer = new RecordIOWriter(dir.resolve("2.log"))){
                writer.writeEvent(eventBytes);
            }

            try(RecordIOWriter writer = new RecordIOWriter(dir.resolve("3.log"))){
                writer.writeEvent(eventBytes);
            }

            // Exercise
            sut.updateOldestSegmentReference();

            // Verify
            final Optional<Path> oldestSegmentPath = sut.getOldestSegmentPath();
            assertTrue(oldestSegmentPath.isPresent());
            assertEquals("1.log", oldestSegmentPath.get().getFileName().toString());
        }
    }

    @Test
    public void testUpdateOldestSegmentReferenceWithDeletedSegment() throws IOException {
        try (DeadLetterQueueWriter sut = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 20 * MB)
                .build()) {

            final byte[] eventBytes = new DLQEntry(new Event(), "", "", "").serialize();
            try(RecordIOWriter writer = new RecordIOWriter(dir.resolve("1.log"))){
                writer.writeEvent(eventBytes);
            }

            try(RecordIOWriter writer = new RecordIOWriter(dir.resolve("2.log"))){
                writer.writeEvent(eventBytes);
            }

            // Exercise
            sut.updateOldestSegmentReference();

            // Delete 1.log (oldest)
            Files.delete(sut.getOldestSegmentPath().get());

            sut.updateOldestSegmentReference();

            // Verify
            assertEquals("2.log",sut.getOldestSegmentPath().get().getFileName().toString());
        }
    }

    @Test
    public void testUpdateOldestSegmentReferenceWithAllDeletedSegments() throws IOException {
        try (DeadLetterQueueWriter sut = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 20 * MB)
                .build()) {

            final byte[] eventBytes = new DLQEntry(new Event(), "", "", "").serialize();
            final String[] allSegments = {"1.log", "2.log"};
            for (String segment : allSegments) {
                try(RecordIOWriter writer = new RecordIOWriter(dir.resolve(segment))){
                    writer.writeEvent(eventBytes);
                }
            }

            // Update with segment files
            sut.updateOldestSegmentReference();
            assertEquals("1.log",sut.getOldestSegmentPath().get().getFileName().toString());

            // Delete all segments
            for (String segment : allSegments) {
                Files.delete(dir.resolve(segment));
            }

            // Update with no segment files
            sut.updateOldestSegmentReference();

            // Verify
            assertTrue(sut.getOldestSegmentPath().isEmpty());
        }
    }

    @Test
    public void testUpdateOldestSegmentReferenceWithNonLexicographicallySortableFileNames() throws IOException {
        try (DeadLetterQueueWriter sut = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 20 * MB)
                .build()) {

            final byte[] eventBytes = new DLQEntry(new Event(), "", "", "").serialize();
            try(RecordIOWriter writer = new RecordIOWriter(dir.resolve("2.log"))){
                writer.writeEvent(eventBytes);
            }

            try(RecordIOWriter writer = new RecordIOWriter(dir.resolve("10.log"))){
                writer.writeEvent(eventBytes);
            }

            // Exercise
            sut.updateOldestSegmentReference();

            // Verify
            assertEquals("2.log",sut.getOldestSegmentPath().get().getFileName().toString());
        }
    }

    @Test
    public void testReadTimestampOfLastEventInSegment() throws IOException {
        final Timestamp expectedTimestamp = Timestamp.now();
        final byte[] eventBytes = new DLQEntry(new Event(), "", "", "", expectedTimestamp).serialize();

        final Path segmentPath = dir.resolve("1.log");
        try (RecordIOWriter writer = new RecordIOWriter(segmentPath)) {
            writer.writeEvent(eventBytes);
        }

        // Exercise
        Optional<Timestamp> timestamp = DeadLetterQueueWriter.readTimestampOfLastEventInSegment(segmentPath);

        // Verify
        assertTrue(timestamp.isPresent());
        assertEquals(expectedTimestamp, timestamp.get());
    }

    @Test
    public void testReadTimestampOfLastEventInSegmentWithDeletedSegment() throws IOException {
        // Exercise
        Optional<Timestamp> timestamp = DeadLetterQueueWriter.readTimestampOfLastEventInSegment(Path.of("non_existing_file.txt"));

        // Verify
        assertTrue(timestamp.isEmpty());
    }

    @Test
    public void testDropEventCountCorrectlyNotEnqueuedEvents() throws IOException, InterruptedException {
        Event blockAlmostFullEvent = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(Collections.emptyMap());
        int serializationHeader = 286;
        int notEnoughHeaderSpace = 5;
        blockAlmostFullEvent.setField("message", DeadLetterQueueReaderTest.generateMessageContent(BLOCK_SIZE - serializationHeader - RECORD_HEADER_SIZE + notEnoughHeaderSpace));

        Event bigEvent = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(Collections.emptyMap());
        bigEvent.setField("message", DeadLetterQueueReaderTest.generateMessageContent(2 * BLOCK_SIZE));

        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 20 * MB, Duration.ofSeconds(1))
                .build()) {
            // enqueue a record with size smaller than BLOCK_SIZE
            DLQEntry entry = new DLQEntry(blockAlmostFullEvent, "", "", "00001", DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(System.currentTimeMillis()));
            assertEquals("Serialized plus header must not leave enough space for another record header ",
                    entry.serialize().length, BLOCK_SIZE - RECORD_HEADER_SIZE - notEnoughHeaderSpace);
            writeManager.writeEntry(entry);

            // enqueue a record bigger than BLOCK_SIZE
            entry = new DLQEntry(bigEvent, "", "", "00002", DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(System.currentTimeMillis()));
            assertThat("Serialized entry has to split in multiple blocks", entry.serialize().length, is(greaterThan(2 * BLOCK_SIZE)));
            writeManager.writeEntry(entry);
        }

        // fill the queue to push out the segment with the 2 previous events
        Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(Collections.emptyMap());
        event.setField("message", DeadLetterQueueReaderTest.generateMessageContent(32479));
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 20 * MB, Duration.ofSeconds(1))
                .storageType(QueueStorageType.DROP_NEWER)
                .build()) {

            long startTime = System.currentTimeMillis();
            // 319 events of 32K generates almost 2 segments of 10 Mb of data
            for (int i = 0; i < (320 * 2) - 2; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", i), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(startTime));
                final int serializationLength = entry.serialize().length;
                assertEquals("Serialized entry fills block payload", BLOCK_SIZE - RECORD_HEADER_SIZE, serializationLength);
                if (i == 636) {
                    // wait flusher thread flushes the data. When DLQ full condition is reached then the size is checked against
                    // the effective file sizes loaded from FS. This is due to writer-reader interaction
                    Thread.sleep(2_000);
                }
                writeManager.writeEntry(entry);
            }

            // 1.log with 2 events
            // 2.log with 319
            // 3.log with 319
            assertEquals(2, writeManager.getDroppedEvents());
        }
    }

    @Test(expected = Test.None.class)
    public void testInitializeWriterWith1ByteEntry() throws Exception {
        Files.write(dir.resolve("1.log"), "1".getBytes());

        DeadLetterQueueWriter writer = DeadLetterQueueWriter
                .newBuilder(dir, 1_000, 100_000, Duration.ofSeconds(1))
                .build();
        writer.close();
    }
}
