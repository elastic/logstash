/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


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

import java.io.Closeable;
import java.io.IOException;
import java.nio.channels.FileLock;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.TemporalAmount;
import java.util.Locale;
import java.util.Optional;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.atomic.LongAdder;
import java.util.concurrent.locks.ReentrantLock;

import com.google.common.annotations.VisibleForTesting;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.DLQEntry;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.FileLockFactory;
import org.logstash.Timestamp;

import static org.logstash.common.io.DeadLetterQueueUtils.listFiles;
import static org.logstash.common.io.DeadLetterQueueUtils.listSegmentPaths;
import static org.logstash.common.io.DeadLetterQueueUtils.listSegmentPathsSortedBySegmentId;
import static org.logstash.common.io.RecordIOReader.SegmentStatus;
import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION_SIZE;

public final class DeadLetterQueueWriter implements Closeable {

    private enum FinalizeWhen { ALWAYS, ONLY_IF_STALE }

    private enum SealReason {
        DLQ_CLOSE("Dead letter queue is closing"),
        SCHEDULED_FLUSH("the segment has expired 'flush_interval'"),
        SEGMENT_FULL("the segment has reached its maximum size");

        final String motivation;

        SealReason(String motivation) {
            this.motivation = motivation;
        }

        @Override
        public String toString() {
            return motivation;
        }
    }

    @VisibleForTesting
    static final String SEGMENT_FILE_PATTERN = "%d.log";
    private static final Logger logger = LogManager.getLogger(DeadLetterQueueWriter.class);
    private static final String TEMP_FILE_PATTERN = "%d.log.tmp";
    private static final String LOCK_FILE = ".lock";
    private static final FieldReference DEAD_LETTER_QUEUE_METADATA_KEY =
            FieldReference.from(String.format("%s[dead_letter_queue]", Event.METADATA_BRACKETS));
    private final ReentrantLock lock = new ReentrantLock();
    private final long maxSegmentSize;
    private final long maxQueueSize;
    private final QueueStorageType storageType;
    private final AtomicLong currentQueueSize;
    private final Path queuePath;
    private final FileLock fileLock;
    private volatile RecordIOWriter currentWriter;
    private volatile int currentSegmentIndex;
    private volatile Timestamp lastEntryTimestamp;
    private final Duration flushInterval;
    private Instant lastWrite;
    private final AtomicBoolean open = new AtomicBoolean(true);
    private ScheduledExecutorService flushScheduler;
    private final LongAdder droppedEvents = new LongAdder();
    private final LongAdder expiredEvents = new LongAdder();
    private volatile String lastError = "no errors";
    private final Clock clock;
    private volatile Optional<Timestamp> oldestSegmentTimestamp;
    private volatile Optional<Path> oldestSegmentPath = Optional.empty();
    private final TemporalAmount retentionTime;

    private final SchedulerService flusherService;

    interface SchedulerService {

        /**
         * Register the callback action to invoke on every clock tick.
         * */
        void repeatedAction(Runnable action);
    }

    private static class FixedRateScheduler implements SchedulerService {

        private final ScheduledExecutorService scheduledExecutor;

        FixedRateScheduler() {
            scheduledExecutor = Executors.newScheduledThreadPool(1, r -> {
                Thread t = new Thread(r);
                //Allow this thread to die when the JVM dies
                t.setDaemon(true);
                //Set the name
                t.setName("dlq-flush-check");
                return t;
            });
        }

        @Override
        public void repeatedAction(Runnable action) {
            scheduledExecutor.scheduleAtFixedRate(action, 1L, 1L, TimeUnit.SECONDS);
        }
    }

    private static class NoopScheduler implements SchedulerService {
        @Override
        public void repeatedAction(Runnable action) {
            // Noop
        }
    }

    public static final class Builder {

        private final Path queuePath;
        private final long maxSegmentSize;
        private final long maxQueueSize;
        private final Duration flushInterval;
        private boolean startScheduledFlusher;
        private QueueStorageType storageType = QueueStorageType.DROP_NEWER;
        private Duration retentionTime = null;
        private Clock clock = Clock.systemDefaultZone();
        private SchedulerService customSchedulerService = null;

        private Builder(Path queuePath, long maxSegmentSize, long maxQueueSize, Duration flushInterval) {
            this(queuePath, maxSegmentSize, maxQueueSize, flushInterval, true);
        }

        private Builder(Path queuePath, long maxSegmentSize, long maxQueueSize, Duration flushInterval, boolean startScheduledFlusher) {
            this.queuePath = queuePath;
            this.maxSegmentSize = maxSegmentSize;
            this.maxQueueSize = maxQueueSize;
            this.flushInterval = flushInterval;
            this.startScheduledFlusher = startScheduledFlusher;
        }

        public Builder storageType(QueueStorageType storageType) {
            this.storageType = storageType;
            return this;
        }

        public Builder retentionTime(Duration retentionTime) {
            this.retentionTime = retentionTime;
            return this;
        }

        @VisibleForTesting
        Builder clock(Clock clock) {
            this.clock = clock;
            return this;
        }

        @VisibleForTesting
        Builder flusherService(SchedulerService service) {
            this.customSchedulerService = service;
            return this;
        }

        public DeadLetterQueueWriter build() throws IOException {
            if (customSchedulerService != null && startScheduledFlusher) {
                throw new IllegalArgumentException("Both default scheduler and custom scheduler were defined, ");
            }
            SchedulerService schedulerService;
            if (customSchedulerService != null) {
                schedulerService = customSchedulerService;
            } else {
                if (startScheduledFlusher) {
                    schedulerService = new FixedRateScheduler();
                } else {
                    schedulerService = new NoopScheduler();
                }
            }

            return new DeadLetterQueueWriter(queuePath, maxSegmentSize, maxQueueSize, flushInterval, storageType, retentionTime, clock, schedulerService);
        }
    }

    public static Builder newBuilder(final Path queuePath, final long maxSegmentSize, final long maxQueueSize,
                                     final Duration flushInterval) {
        return new Builder(queuePath, maxSegmentSize, maxQueueSize, flushInterval);
    }

    @VisibleForTesting
    static Builder newBuilderWithoutFlusher(final Path queuePath, final long maxSegmentSize, final long maxQueueSize) {
        return new Builder(queuePath, maxSegmentSize, maxQueueSize, Duration.ZERO, false);
    }

    private DeadLetterQueueWriter(final Path queuePath, final long maxSegmentSize, final long maxQueueSize,
                                  final Duration flushInterval, final QueueStorageType storageType, final Duration retentionTime,
                                  final Clock clock, SchedulerService flusherService) throws IOException {
        this.clock = clock;

        this.fileLock = FileLockFactory.obtainLock(queuePath, LOCK_FILE);
        this.queuePath = queuePath;
        this.maxSegmentSize = maxSegmentSize;
        this.maxQueueSize = maxQueueSize;
        this.storageType = storageType;
        this.flushInterval = flushInterval;
        this.currentQueueSize = new AtomicLong(computeQueueSize());
        this.retentionTime = retentionTime;

        cleanupTempFiles();
        updateOldestSegmentReference();
        currentSegmentIndex = listSegmentPaths(queuePath)
                .map(s -> s.getFileName().toString().split("\\.")[0])
                .mapToInt(Integer::parseInt)
                .max().orElse(0);
        nextWriter();
        this.lastEntryTimestamp = Timestamp.now();
        this.flusherService = flusherService;
        this.flusherService.repeatedAction(this::scheduledFlushCheck);
    }

    public boolean isOpen() {
        return open.get();
    }

    public Path getPath() {
        return queuePath;
    }

    public long getCurrentQueueSize() {
        return currentQueueSize.longValue();
    }

    public String getStoragePolicy() {
        return storageType.name().toLowerCase(Locale.ROOT);
    }

    public long getDroppedEvents() {
        return droppedEvents.longValue();
    }

    public long getExpiredEvents() {
        return expiredEvents.longValue();
    }

    public String getLastError() {
        return lastError;
    }

    public void writeEntry(Event event, String pluginName, String pluginId, String reason) throws IOException {
        writeEntry(new DLQEntry(event, pluginName, pluginId, reason));
    }

    @Override
    public void close() {
        if (open.compareAndSet(true, false)) {
            try {
                finalizeSegment(FinalizeWhen.ALWAYS, SealReason.DLQ_CLOSE);
            } catch (Exception e) {
                logger.warn("Unable to close dlq writer, ignoring", e);
            }
            try {
                releaseFileLock();
            } catch (Exception e) {
                logger.warn("Unable to release fileLock, ignoring", e);
            }

            try {
                // flushScheduler is null only if it's not explicitly started, which happens only in tests.
                if (flushScheduler != null) {
                    flushScheduler.shutdown();
                }
            } catch (Exception e) {
                logger.warn("Unable shutdown flush scheduler, ignoring", e);
            }
        }
    }

    @VisibleForTesting
    void writeEntry(DLQEntry entry) throws IOException {
        lock.lock();
        try {
            Timestamp entryTimestamp = Timestamp.now();
            if (entryTimestamp.compareTo(lastEntryTimestamp) < 0) {
                entryTimestamp = lastEntryTimestamp;
            }
            innerWriteEntry(entry);
            lastEntryTimestamp = entryTimestamp;
        } finally {
            lock.unlock();
        }
    }

    private void innerWriteEntry(DLQEntry entry) throws IOException {
        Event event = entry.getEvent();

        if (alreadyProcessed(event)) {
            logger.warn("Event previously submitted to dead letter queue. Skipping...");
            return;
        }
        byte[] record = entry.serialize();
        int eventPayloadSize = RECORD_HEADER_SIZE + record.length;
        executeAgeRetentionPolicy();
        boolean skipWrite = executeStoragePolicy(eventPayloadSize);
        if (skipWrite) {
            return;
        }

        if (exceedSegmentSize(eventPayloadSize)) {
            finalizeSegment(FinalizeWhen.ALWAYS, SealReason.SEGMENT_FULL);
        }
        long writtenBytes = currentWriter.writeEvent(record);
        currentQueueSize.getAndAdd(writtenBytes);
        lastWrite = Instant.now();
    }

    private boolean exceedSegmentSize(int eventPayloadSize) throws IOException {
        return currentWriter.getPosition() + eventPayloadSize > maxSegmentSize;
    }

    private void executeAgeRetentionPolicy() {
        if (isOldestSegmentExpired()) {
            try {
                deleteExpiredSegments();
            } catch (IOException ex) {
                logger.error("Can't remove some DLQ files while cleaning expired segments", ex);
            }
        }
    }

    /**
     * @param eventPayloadSize payload size in bytes.
     * @return boolean true if event write has to be skipped.
     * */
    private boolean executeStoragePolicy(int eventPayloadSize) {
        if (!exceedMaxQueueSize(eventPayloadSize)) {
            return false;
        }

        // load currentQueueSize from filesystem because there could be a consumer
        // that's already cleaning
        try {
            this.currentQueueSize.set(computeQueueSize());
        } catch (IOException ex) {
            logger.warn("Unable to determine DLQ size, skipping storage policy check", ex);
            return false;
        }

        // after reload verify the condition is still valid
        if (!exceedMaxQueueSize(eventPayloadSize)) {
            return false;
        }

        if (storageType == QueueStorageType.DROP_NEWER) {
            lastError = String.format("Cannot write event to DLQ(path: %s): reached maxQueueSize of %d", queuePath, maxQueueSize);
            logger.error(lastError);
            droppedEvents.add(1L);
            return true;
        } else {
            try {
                do {
                    dropTailSegment();
                } while (exceedMaxQueueSize(eventPayloadSize));
            } catch (IOException ex) {
                logger.error("Can't remove some DLQ files while removing older segments", ex);
            }
            return false;
        }
    }

    private boolean exceedMaxQueueSize(int eventPayloadSize) {
        return currentQueueSize.longValue() + eventPayloadSize > maxQueueSize;
    }

    private boolean isOldestSegmentExpired() {
        if (retentionTime == null) {
            return false;
        }
        final Instant now = clock.instant();
        return oldestSegmentTimestamp
                .map(t -> t.toInstant().isBefore(now.minus(retentionTime)))
                .orElse(false);
    }

    private void deleteExpiredSegments() throws IOException {
        // remove all the old segments that verifies the age retention condition
        boolean cleanNextSegment;
        do {
            if (oldestSegmentPath.isPresent()) {
                Path beheadedSegment = oldestSegmentPath.get();
                expiredEvents.add(deleteTailSegment(beheadedSegment, "age retention policy"));
            }
            updateOldestSegmentReference();
            cleanNextSegment = isOldestSegmentExpired();
        } while (cleanNextSegment);

        this.currentQueueSize.set(computeQueueSize());
    }

    /**
     * Deletes the segment path, if present. Also return the number of events it contains.
     *
     * @param segment
     *      The segment file to delete.
     * @param motivation
     *      Description of delete motivation.
     * @return the number of events contained in the segment or 0 if the segment was already removed.
     * @throws IOException if any other IO related error happens during deletion of the segment.
     * */
    private long deleteTailSegment(Path segment, String motivation) throws IOException {
        try {
            long eventsInSegment = DeadLetterQueueUtils.countEventsInSegment(segment);
            Files.delete(segment);
            logger.debug("Removed segment file {} due to {}", segment, motivation);
            return eventsInSegment;
        } catch (NoSuchFileException nsfex) {
            // the last segment was deleted by another process, maybe the reader that's cleaning consumed segments
            logger.debug("File not found {}, maybe removed by the reader pipeline", segment);
            return 0;
        }
    }

    // package-private for testing
    void updateOldestSegmentReference() throws IOException {
        final Optional<Path> previousOldestSegmentPath = oldestSegmentPath;
        oldestSegmentPath = listSegmentPathsSortedBySegmentId(this.queuePath)
                .filter(p -> p.toFile().length() > 1) // take the files that have content to process
                .findFirst();
        if (!oldestSegmentPath.isPresent()) {
            oldestSegmentTimestamp = Optional.empty();
            return;
        }

        boolean previousPathEqualsToCurrent = previousOldestSegmentPath.isPresent() && // contains a value
                previousOldestSegmentPath.get().equals(oldestSegmentPath.get()); // and the value is the same as the current
        if (!previousPathEqualsToCurrent) {
            // oldest segment path has changed
            logger.debug("Oldest segment is {}", oldestSegmentPath.get());
        }

        // extract the newest timestamp from the oldest segment
        Optional<Timestamp> foundTimestamp = readTimestampOfLastEventInSegment(oldestSegmentPath.get());
        if (!foundTimestamp.isPresent()) {
            // clean also the last segment, because doesn't contain a timestamp (corrupted maybe)
            // or is not present anymore
            oldestSegmentPath = Optional.empty();
        }
        oldestSegmentTimestamp = foundTimestamp;
    }

    // package-private for testing
    Optional<Path> getOldestSegmentPath() {
        return oldestSegmentPath;
    }

    /**
     * Extract the timestamp from the last DLQEntry it finds in the given segment.
     * Start from the end of the latest block, and going backward try to read the next event from its start.
     * */
    static Optional<Timestamp> readTimestampOfLastEventInSegment(Path segmentPath) throws IOException {
        byte[] eventBytes = null;
        try (RecordIOReader recordReader = new RecordIOReader(segmentPath)) {
            int blockId = (int) Math.ceil(((Files.size(segmentPath) - VERSION_SIZE) / (double) BLOCK_SIZE)) - 1;;
            while (eventBytes == null && blockId >= 0) { // no event present in last block, try with the one before
                recordReader.seekToBlock(blockId);
                eventBytes = recordReader.readEvent();
                blockId--;
            }
        } catch (NoSuchFileException nsfex) {
            // the segment file may have been removed by the clean consumed feature on the reader side
            return Optional.empty();
        }
        if (eventBytes == null) {
            logger.warn("Cannot find a complete event into the segment file [{}], this is a DLQ segment corruption", segmentPath);
            return Optional.empty();
        }
        return Optional.of(DLQEntry.deserialize(eventBytes).getEntryTime());
    }

    // package-private for testing
    void dropTailSegment() throws IOException {
        // remove oldest segment
        final Optional<Path> oldestSegment = listSegmentPathsSortedBySegmentId(queuePath).findFirst();
        if (oldestSegment.isPresent()) {
            final Path beheadedSegment = oldestSegment.get();
            deleteTailSegment(beheadedSegment, "dead letter queue size exceeded dead_letter_queue.max_bytes size(" + maxQueueSize + ")");
        } else {
            logger.info("Queue size {} exceeded, but no complete DLQ segments found", maxQueueSize);
        }
        this.currentQueueSize.set(computeQueueSize());
    }

    /**
     * Method to determine whether the event has already been processed by the DLQ - currently this
     * just checks the metadata to see if metadata has been added to the event that indicates that
     * it has already gone through the DLQ.
     * TODO: Add metadata around 'depth' to enable >1 iteration through the DLQ if required.
     * @param event Logstash Event
     * @return boolean indicating whether the event is eligible to be added to the DLQ
     */
    private static boolean alreadyProcessed(final Event event) {
        return event.includes(DEAD_LETTER_QUEUE_METADATA_KEY);
    }

    private void scheduledFlushCheck() {
        logger.trace("Running scheduled check");
        lock.lock();
        try {
            finalizeSegment(FinalizeWhen.ONLY_IF_STALE, SealReason.SCHEDULED_FLUSH);

            updateOldestSegmentReference();
            executeAgeRetentionPolicy();
        } catch (Exception e) {
            logger.warn("Unable to finalize segment", e);
        } finally {
            lock.unlock();
        }
    }

    /**
     * Determines whether the current writer is stale. It is stale if writes have been performed, but the
     * last time it was written is further in the past than the flush interval.
     * @return true if the current segment is stale.
     */
    private boolean isCurrentWriterStale() {
        return currentWriter.isStale(flushInterval);
    }

    private void finalizeSegment(final FinalizeWhen finalizeWhen, SealReason sealReason) throws IOException {
        lock.lock();
        try {
            if (!isCurrentWriterStale() && finalizeWhen == FinalizeWhen.ONLY_IF_STALE)
                return;

            if (currentWriter != null) {
                if (currentWriter.hasWritten()) {
                    currentWriter.close();
                    sealSegment(currentSegmentIndex, sealReason);
                }
                updateOldestSegmentReference();
                executeAgeRetentionPolicy();
                if (isOpen() && currentWriter.hasWritten()) {
                    nextWriter();
                }
            }
        } finally {
            lock.unlock();
        }
    }

    private void sealSegment(int segmentIndex, SealReason motivation) throws IOException {
        Files.move(queuePath.resolve(String.format(TEMP_FILE_PATTERN, segmentIndex)),
                queuePath.resolve(String.format(SEGMENT_FILE_PATTERN, segmentIndex)),
                StandardCopyOption.ATOMIC_MOVE);
        logger.debug("Sealed segment with index {} because {}", segmentIndex, motivation);
    }

    private void createFlushScheduler() {
        flushScheduler = Executors.newScheduledThreadPool(1, r -> {
            Thread t = new Thread(r);
            //Allow this thread to die when the JVM dies
            t.setDaemon(true);
            //Set the name
            t.setName("dlq-flush-check");
            return t;
        });
        flushScheduler.scheduleAtFixedRate(this::scheduledFlushCheck, 1L, 1L, TimeUnit.SECONDS);
    }


    private long computeQueueSize() throws IOException {
        return listSegmentPaths(this.queuePath)
                .mapToLong(DeadLetterQueueWriter::safeFileSize)
                .sum();
    }

    private static long safeFileSize(Path p) {
        try {
            return Files.size(p);
        } catch (IOException e) {
            return 0L;
        }
    }

    private void releaseFileLock() {
        try {
            FileLockFactory.releaseLock(fileLock);
        } catch (IOException e) {
            logger.debug("Unable to release fileLock", e);
        }
        try {
            Files.deleteIfExists(queuePath.resolve(LOCK_FILE));
        } catch (IOException e){
            logger.debug("Unable to delete fileLock file", e);
        }
    }

    private void nextWriter() throws IOException {
        Path nextSegmentPath = queuePath.resolve(String.format(TEMP_FILE_PATTERN, ++currentSegmentIndex));
        currentWriter = new RecordIOWriter(nextSegmentPath);
        currentQueueSize.incrementAndGet();
        logger.debug("Created new head segment {}", nextSegmentPath);
    }

    // Clean up existing temp files - files with an extension of .log.tmp. Either delete them if an existing
    // segment file with the same base name exists, or rename the
    // temp file to the segment file, which can happen when a process ends abnormally
    private void cleanupTempFiles() throws IOException {
        listFiles(queuePath, ".log.tmp")
                .forEach(this::cleanupTempFile);
    }

    // check if there is a corresponding .log file - if yes delete the temp file, if no atomic move the
    // temp file to be a new segment file..
    private void cleanupTempFile(final Path tempFile) {
        String segmentName = tempFile.getFileName().toString().split("\\.")[0];
        Path segmentFile = queuePath.resolve(String.format("%s.log", segmentName));
        try {
            if (Files.exists(segmentFile)) {
                Files.delete(tempFile);
                logger.debug("Deleted temporary file {}", tempFile);
            } else {
                SegmentStatus segmentStatus = RecordIOReader.getSegmentStatus(tempFile);
                switch (segmentStatus) {
                    case VALID:
                        logger.debug("Moving temp file {} to segment file {}", tempFile, segmentFile);
                        Files.move(tempFile, segmentFile, StandardCopyOption.ATOMIC_MOVE);
                        break;
                    case EMPTY:
                        deleteTemporaryEmptyFile(tempFile, segmentName);
                        break;
                    case INVALID:
                        Path errorFile = queuePath.resolve(String.format("%s.err", segmentName));
                        logger.warn("Segment file {} is in an error state, saving as {}", segmentFile, errorFile);
                        Files.move(tempFile, errorFile, StandardCopyOption.ATOMIC_MOVE);
                        break;
                    default:
                        throw new IllegalStateException("Unexpected value: " + RecordIOReader.getSegmentStatus(tempFile));
                }
            }
        } catch (IOException e) {
            throw new IllegalStateException("Unable to clean up temp file: " + tempFile, e);
        }
    }

    // Windows can leave files in a "Delete pending" state, where the file presents as existing to certain
    // methods, and not to others, and actively prevents a new file being created with the same file name,
    // throwing AccessDeniedException. This method moves the temporary file to a .del file before
    // deletion, enabling a new temp file to be created in its place.
    private void deleteTemporaryEmptyFile(Path tempFile, String segmentName) throws IOException {
        Path deleteTarget;
        if (isWindows()) {
            Path deletedFile = queuePath.resolve(String.format("%s.del", segmentName));
            logger.debug("Moving temp file {} to {}", tempFile, deletedFile);
            deleteTarget = deletedFile;
            Files.move(tempFile, deletedFile, StandardCopyOption.ATOMIC_MOVE);
        } else {
            deleteTarget = tempFile;
        }
        Files.delete(deleteTarget);
        logger.debug("Deleted temporary empty file {}", deleteTarget);
    }

    private static boolean isWindows() {
        return System.getProperty("os.name").startsWith("Windows");
    }
}
