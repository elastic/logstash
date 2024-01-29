package org.logstash.common.io;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Collections;
import java.util.Set;
import java.util.stream.Collectors;

import org.awaitility.Awaitility;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.DLQEntry;
import org.logstash.Event;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.not;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assume.assumeThat;
import static org.logstash.common.io.DeadLetterQueueTestUtils.FULL_SEGMENT_FILE_SIZE;
import static org.logstash.common.io.DeadLetterQueueTestUtils.GB;
import static org.logstash.common.io.DeadLetterQueueTestUtils.MB;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION_SIZE;

public class DeadLetterQueueWriterAgeRetentionTest {

    // 319 events of 32Kb generates 10 Mb of data
    private static final int EVENTS_TO_FILL_A_SEGMENT = 319;
    private ForwardableClock fakeClock;

    static class ForwardableClock extends Clock {

        private Clock currentClock;

        ForwardableClock(Clock clock) {
            this.currentClock = clock;
        }

        void forward(Duration period) {
            currentClock = Clock.offset(currentClock, period);
        }

        @Override
        public ZoneId getZone() {
            return currentClock.getZone();
        }

        @Override
        public Clock withZone(ZoneId zone) {
            return currentClock.withZone(zone);
        }

        @Override
        public Instant instant() {
            return currentClock.instant();
        }
    }

    private static class SynchronizedScheduledService implements DeadLetterQueueWriter.SchedulerService {

        private Runnable action;

        @Override
        public void repeatedAction(Runnable action) {
            this.action = action;
        }

        void executeAction() {
            action.run();
        }
    }

    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    private SynchronizedScheduledService synchScheduler;

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
        final Clock pointInTimeFixedClock = Clock.fixed(Instant.parse("2022-02-22T10:20:30.00Z"), ZoneId.of("Europe/Rome"));
        fakeClock = new ForwardableClock(pointInTimeFixedClock);
        synchScheduler = new SynchronizedScheduledService();
    }

    @Test
    public void testRemovesOlderSegmentsWhenWriteOnReopenedDLQContainingExpiredSegments() throws IOException {
        final Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(Collections.emptyMap());
        event.setField("message", DeadLetterQueueReaderTest.generateMessageContent(32479));

        final Clock pointInTimeFixedClock = Clock.fixed(Instant.parse("2022-02-22T10:20:30.00Z"), ZoneId.of("Europe/Rome"));
        final ForwardableClock fakeClock = new ForwardableClock(pointInTimeFixedClock);
        // given DLQ with first segment filled of expired events
        prepareDLQWithFirstSegmentOlderThanRetainPeriod(event, fakeClock, Duration.ofDays(2));

        // Exercise
        final long prevQueueSize;
        final long beheadedQueueSize;
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 1 * GB, Duration.ofSeconds(1))
                .retentionTime(Duration.ofDays(2))
                .clock(fakeClock)
                .build()) {
            prevQueueSize = writeManager.getCurrentQueueSize();
            assertEquals("Queue size is composed of one just one empty file with version byte", VERSION_SIZE, prevQueueSize);

            // write new entry that trigger clean of age retained segment
            DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", 320), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(System.currentTimeMillis()));
            // when a new write happens in a reopened queue
            writeManager.writeEntry(entry);
            beheadedQueueSize = writeManager.getCurrentQueueSize();
            assertEquals("No event is expired after reopen of DLQ", 0, writeManager.getExpiredEvents());
        }

        // then the age policy must remove the expired segments
        assertEquals("Write should push off the age expired segments", VERSION_SIZE + BLOCK_SIZE, beheadedQueueSize);
    }

    private void prepareDLQWithFirstSegmentOlderThanRetainPeriod(Event event, ForwardableClock fakeClock, Duration retainedPeriod) throws IOException {
        final Duration littleMoreThanRetainedPeriod = retainedPeriod.plusMinutes(1);
        long startTime = fakeClock.instant().minus(littleMoreThanRetainedPeriod).toEpochMilli();
        int messageSize = 0;
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 1 * GB, Duration.ofSeconds(1))
                .retentionTime(retainedPeriod)
                .clock(fakeClock)
                .build()) {

            // 320 generates 10 Mb of data
            for (int i = 0; i < EVENTS_TO_FILL_A_SEGMENT; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", i), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(startTime++));
                final int serializationLength = entry.serialize().length;
                assertEquals("setup: serialized entry size...", serializationLength + RECORD_HEADER_SIZE, BLOCK_SIZE);
                messageSize += serializationLength;
                writeManager.writeEntry(entry);
            }
            assertThat(messageSize, is(greaterThan(BLOCK_SIZE)));
        }
    }

    @Test
    public void testRemovesOlderSegmentsWhenWritesIntoDLQContainingExpiredSegments() throws IOException {
        final Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(Collections.emptyMap());
        event.setField("message", DeadLetterQueueReaderTest.generateMessageContent(32479));

        long startTime = fakeClock.instant().toEpochMilli();
        int messageSize = 0;

        final Duration retention = Duration.ofDays(2);
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 1 * GB, Duration.ofSeconds(1))
                .retentionTime(retention)
                .clock(fakeClock)
                .build()) {

            // 319 generates 10 Mb of data
            for (int i = 0; i < EVENTS_TO_FILL_A_SEGMENT; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", i), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(startTime++));
                final int serializationLength = entry.serialize().length;
                assertEquals("setup: serialized entry size...", serializationLength + RECORD_HEADER_SIZE, BLOCK_SIZE);
                messageSize += serializationLength;
                writeManager.writeEntry(entry);
            }
            assertThat(messageSize, is(greaterThan(BLOCK_SIZE)));

            // Exercise
            // write an event that goes in second segment
            fakeClock.forward(retention.plusSeconds(1));
            final long prevQueueSize = writeManager.getCurrentQueueSize();
            assertEquals("Queue size is composed of one full segment files", FULL_SEGMENT_FILE_SIZE, prevQueueSize);

            // write new entry that trigger clean of age retained segment
            DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", 320), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(System.currentTimeMillis()));
            // when a new write happens in the same writer
            writeManager.writeEntry(entry);
            final long beheadedQueueSize = writeManager.getCurrentQueueSize();

            // then the age policy must remove the expired segments
            assertEquals("Write should push off the age expired segments",VERSION_SIZE + BLOCK_SIZE, beheadedQueueSize);
            assertEquals("The number of events removed should count as expired", EVENTS_TO_FILL_A_SEGMENT, writeManager.getExpiredEvents());
        }
    }

    @Test
    public void testRemoveMultipleOldestSegmentsWhenRetainedAgeIsExceeded() throws IOException {
        final Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(Collections.emptyMap());
        event.setField("message", DeadLetterQueueReaderTest.generateMessageContent(32479));

        long startTime = fakeClock.instant().toEpochMilli();
        int messageSize = 0;

        final Duration retention = Duration.ofDays(2);
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 1 * GB, Duration.ofSeconds(1))
                .retentionTime(retention)
                .clock(fakeClock)
                .build()) {

            // given DLQ with a couple of segments filled of expired events
            // 319 generates 10 Mb of data
            for (int i = 0; i < EVENTS_TO_FILL_A_SEGMENT * 2; i++) {
                DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", i), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(startTime++));
                final int serializationLength = entry.serialize().length;
                assertEquals("setup: serialized entry size...", serializationLength + RECORD_HEADER_SIZE, BLOCK_SIZE);
                messageSize += serializationLength;
                writeManager.writeEntry(entry);
            }
            assertThat(messageSize, is(greaterThan(BLOCK_SIZE)));

            // when the age expires the retention and a write is done
            // make the retention age to pass for the first 2 full segments
            fakeClock.forward(retention.plusSeconds(1));

            // Exercise
            // write an event that goes in second segment
            final long prevQueueSize = writeManager.getCurrentQueueSize();
            assertEquals("Queue size is composed of 2 full segment files", 2 * FULL_SEGMENT_FILE_SIZE, prevQueueSize);

            // write new entry that trigger clean of age retained segment
            DLQEntry entry = new DLQEntry(event, "", "", String.format("%05d", 320), DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(System.currentTimeMillis()));
            writeManager.writeEntry(entry);
            final long beheadedQueueSize = writeManager.getCurrentQueueSize();

            // then the age policy must remove the expired segments
            assertEquals("Write should push off the age expired segments",VERSION_SIZE + BLOCK_SIZE, beheadedQueueSize);
            assertEquals("The number of events removed should count as expired", EVENTS_TO_FILL_A_SEGMENT * 2, writeManager.getExpiredEvents());
        }
    }

    @Test
    public void testDLQWriterCloseRemovesExpiredSegmentWhenCurrentWriterIsUntouched() throws IOException {
        final Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(
                Collections.singletonMap("message", "Not so important content"));

        // write some data in the new segment
        final Clock pointInTimeFixedClock = Clock.fixed(Instant.now(), ZoneId.of("Europe/Rome"));
        final ForwardableClock fakeClock = new ForwardableClock(pointInTimeFixedClock);

        Duration retainedPeriod = Duration.ofDays(1);
        long startTime = fakeClock.instant().toEpochMilli();
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 1 * GB)
                .retentionTime(retainedPeriod)
                .clock(fakeClock)
                .build()) {

            DLQEntry entry = new DLQEntry(event, "", "", "00001", DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(startTime));
            writeManager.writeEntry(entry);
        }

        Set<String> segments = listFileNames(dir);
        assertEquals("Once closed the just written segment, only 1 file must be present", Set.of("1.log"), segments);

        // move forward 3 days, so that the first segment becomes eligible to be deleted by the age retention policy
        fakeClock.forward(Duration.ofDays(3));
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 1 * GB)
                .retentionTime(retainedPeriod)
                .clock(fakeClock)
                .build()) {
            // leave it untouched
            assertTrue(writeManager.isOpen());

            // close so that it should clean the expired segments, close in implicitly invoked by try-with-resource statement
        }

        Set<String> actual = listFileNames(dir);
        assertThat("Age expired segment is removed", actual, not(hasItem("1.log")));
    }

    private Set<String> listFileNames(Path path) throws IOException {
        return Files.list(path)
                .map(Path::getFileName)
                .map(Path::toString)
                .collect(Collectors.toSet());
    }

    @Test
    public void testDLQWriterFlusherRemovesExpiredSegmentWhenCurrentWriterIsStale() throws IOException {
        final Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(
                Collections.singletonMap("message", "Not so important content"));

        // write some data in the new segment
        final Clock pointInTimeFixedClock = Clock.fixed(Instant.now(), ZoneId.of("Europe/Rome"));
        final ForwardableClock fakeClock = new ForwardableClock(pointInTimeFixedClock);

        Duration retainedPeriod = Duration.ofDays(1);
        Duration flushInterval = Duration.ofSeconds(1);
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilder(dir, 10 * MB, 1 * GB, flushInterval)
                .retentionTime(retainedPeriod)
                .clock(fakeClock)
                .build()) {

            DLQEntry entry = new DLQEntry(event, "", "", "00001", DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(fakeClock));
            writeManager.writeEntry(entry);
        }

        Set<String> segments = listFileNames(dir);
        assertEquals("Once closed the just written segment, only 1 file must be present", Set.of("1.log"), segments);

        // move forward 3 days, so that the first segment becomes eligible to be deleted by the age retention policy
        fakeClock.forward(Duration.ofDays(3));
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 1 * GB)
                .retentionTime(retainedPeriod)
                .clock(fakeClock)
                .flusherService(synchScheduler)
                .build()) {
            // write an element to make head segment stale
            final Event anotherEvent = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(
                    Collections.singletonMap("message", "Another not so important content"));
            DLQEntry entry = new DLQEntry(anotherEvent, "", "", "00002", DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(fakeClock));
            writeManager.writeEntry(entry);

            triggerExecutionOfFlush();

            // flusher should clean the expired segments
            Set<String> actual = listFileNames(dir);
            assertThat("Age expired segment is removed by flusher", actual, not(hasItem("1.log")));
        }
    }

    private static boolean isWindows() {
        return System.getProperty("os.name").startsWith("Windows");
    }

    @Test
    public void testDLQWriterFlusherRemovesExpiredSegmentWhenCurrentHeadSegmentIsEmpty() throws IOException {
        // https://github.com/elastic/logstash/issues/15768
        assumeThat(isWindows(), is(not(true)));

        final Event event = DeadLetterQueueReaderTest.createEventWithConstantSerializationOverhead(
                Collections.singletonMap("message", "Not so important content"));

        // write some data in the new segment
        final Clock pointInTimeFixedClock = Clock.fixed(Instant.now(), ZoneId.of("Europe/Rome"));
        final ForwardableClock fakeClock = new ForwardableClock(pointInTimeFixedClock);

        Duration retainedPeriod = Duration.ofDays(1);
        try (DeadLetterQueueWriter writeManager = DeadLetterQueueWriter
                .newBuilderWithoutFlusher(dir, 10 * MB, 1 * GB)
                .retentionTime(retainedPeriod)
                .clock(fakeClock)
                .flusherService(synchScheduler)
                .build()) {

            DLQEntry entry = new DLQEntry(event, "", "", "00001", DeadLetterQueueReaderTest.constantSerializationLengthTimestamp(fakeClock));
            writeManager.writeEntry(entry);

            triggerExecutionOfFlush();

            // wait the flush interval so that the current head segment is sealed
            Awaitility.await("After the flush interval head segment is sealed and a fresh empty head is created")
                    .atMost(Duration.ofSeconds(1))
                    .until(()  -> Set.of("1.log", "2.log.tmp", ".lock").equals(listFileNames(dir)));

            // move forward the time so that the age policy is kicked in when the current head segment is empty
            fakeClock.forward(retainedPeriod.plusMinutes(2));

            triggerExecutionOfFlush();

            // wait the flush period
            Awaitility.await("Remains the untouched head segment while the expired is removed")
                    // wait at least the flush period
                    .atMost(Duration.ofSeconds(1))
                    // check the expired sealed segment is removed
                    .until(()  -> Set.of("2.log.tmp", ".lock").equals(listFileNames(dir)));
        }
    }

    private void triggerExecutionOfFlush() {
        synchScheduler.executeAction();
    }
}
