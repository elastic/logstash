package org.logstash.common.io;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.util.Collections;

import org.hamcrest.Matchers;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;
import org.logstash.DLQEntry;
import org.logstash.Event;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.greaterThan;
import static org.junit.Assert.assertEquals;
import static org.logstash.common.io.DeadLetterQueueTestUtils.FULL_SEGMENT_FILE_SIZE;
import static org.logstash.common.io.DeadLetterQueueTestUtils.GB;
import static org.logstash.common.io.DeadLetterQueueTestUtils.MB;
import static org.logstash.common.io.RecordIOWriter.*;

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

    private Path dir;

    @Rule
    public TemporaryFolder temporaryFolder = new TemporaryFolder();

    @Before
    public void setUp() throws Exception {
        dir = temporaryFolder.newFolder().toPath();
        final Clock pointInTimeFixedClock = Clock.fixed(Instant.parse("2022-02-22T10:20:30.00Z"), ZoneId.of("Europe/Rome"));
        fakeClock = new ForwardableClock(pointInTimeFixedClock);
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
            assertThat(messageSize, Matchers.is(greaterThan(BLOCK_SIZE)));
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
            assertThat(messageSize, Matchers.is(greaterThan(BLOCK_SIZE)));

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
            assertThat(messageSize, Matchers.is(greaterThan(BLOCK_SIZE)));

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
}
