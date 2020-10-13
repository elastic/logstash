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
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Duration;
import java.time.Instant;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;
import java.util.concurrent.locks.ReentrantLock;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import com.google.common.annotations.VisibleForTesting;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.DLQEntry;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.FileLockFactory;
import org.logstash.Timestamp;

import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOReader.SegmentStatus;

public final class DeadLetterQueueWriter implements Closeable {

    @VisibleForTesting
    static final String SEGMENT_FILE_PATTERN = "%d.log";
    private static final Logger logger = LogManager.getLogger(DeadLetterQueueWriter.class);
    private enum FinalizeWhen {ALWAYS, ONLY_IF_STALE};
    private static final String TEMP_FILE_PATTERN = "%d.log.tmp";
    private static final String LOCK_FILE = ".lock";
    private final ReentrantLock lock = new ReentrantLock();
    private static final FieldReference DEAD_LETTER_QUEUE_METADATA_KEY =
        FieldReference.from(String.format("%s[dead_letter_queue]", Event.METADATA_BRACKETS));
    private final long maxSegmentSize;
    private final long maxQueueSize;
    private LongAdder currentQueueSize;
    private final Path queuePath;
    private final FileLock fileLock;
    private volatile RecordIOWriter currentWriter;
    private int currentSegmentIndex;
    private Timestamp lastEntryTimestamp;
    private Duration flushInterval;
    private Instant lastWrite;
    private final AtomicBoolean open = new AtomicBoolean(true);
    private ScheduledExecutorService flushScheduler;

    public DeadLetterQueueWriter(final Path queuePath, final long maxSegmentSize, final long maxQueueSize, final Duration flushInterval) throws IOException {
        this.fileLock = FileLockFactory.obtainLock(queuePath, LOCK_FILE);
        this.queuePath = queuePath;
        this.maxSegmentSize = maxSegmentSize;
        this.maxQueueSize = maxQueueSize;
        this.flushInterval = flushInterval;
        this.currentQueueSize = new LongAdder();
        this.currentQueueSize.add(getStartupQueueSize());

        cleanupTempFiles();
        currentSegmentIndex = getSegmentPaths(queuePath)
                .map(s -> s.getFileName().toString().split("\\.")[0])
                .mapToInt(Integer::parseInt)
                .max().orElse(0);
        nextWriter();
        this.lastEntryTimestamp = Timestamp.now();
        createFlushScheduler();
    }

    public boolean isOpen() {
        return open.get();
    }

    public Path getPath(){
        return queuePath;
    }

    public long getCurrentQueueSize() {
        return currentQueueSize.longValue();
    }

    public void writeEntry(Event event, String pluginName, String pluginId, String reason) throws IOException {
        writeEntry(new DLQEntry(event, pluginName, pluginId, reason));
    }

    @Override
    public void close() {
        if (open.compareAndSet(true, false)) {
            try {
                finalizeSegment(FinalizeWhen.ALWAYS);
            } catch (Exception e) {
                logger.warn("Unable to close dlq writer, ignoring", e);
            }
            try {
                releaseFileLock();
            } catch (Exception e) {
                logger.warn("Unable to release fileLock, ignoring", e);
            }

            try {
                flushScheduler.shutdown();
            } catch (Exception e) {
                logger.warn("Unable shutdown flush scheduler, ignoring", e);
            }
        }
    }

    static Stream<Path> getSegmentPaths(Path path) throws IOException {
        return listFiles(path, ".log");
    }

    @VisibleForTesting
    void writeEntry(DLQEntry entry) throws IOException {
        lock.lock();
        try {
            Timestamp entryTimestamp = Timestamp.now();
            if (entryTimestamp.getTime().isBefore(lastEntryTimestamp.getTime())) {
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
        if (currentQueueSize.longValue() + eventPayloadSize > maxQueueSize) {
            logger.error("cannot write event to DLQ(path: " + this.queuePath + "): reached maxQueueSize of " + maxQueueSize);
            return;
        } else if (currentWriter.getPosition() + eventPayloadSize > maxSegmentSize) {
            finalizeSegment(FinalizeWhen.ALWAYS);
        }
        currentQueueSize.add(currentWriter.writeEvent(record));
        lastWrite = Instant.now();
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

    private void flushCheck() {
        try{
            finalizeSegment(FinalizeWhen.ONLY_IF_STALE);
        } catch (Exception e){
            logger.warn("unable to finalize segment", e);
        }
    }

    /**
     * Determines whether the current writer is stale. It is stale if writes have been performed, but the
     * last time it was written is further in the past than the flush interval.
     * @return
     */
    private boolean isCurrentWriterStale(){
        return currentWriter.isStale(flushInterval);
    }

    private void finalizeSegment(final FinalizeWhen finalizeWhen) throws IOException {
        lock.lock();
        try {
            if (!isCurrentWriterStale() && finalizeWhen == FinalizeWhen.ONLY_IF_STALE)
                return;

            if (currentWriter != null && currentWriter.hasWritten()) {
                currentWriter.close();
                Files.move(queuePath.resolve(String.format(TEMP_FILE_PATTERN, currentSegmentIndex)),
                        queuePath.resolve(String.format(SEGMENT_FILE_PATTERN, currentSegmentIndex)),
                        StandardCopyOption.ATOMIC_MOVE);
                if (isOpen()) {
                    nextWriter();
                }
            }
        } finally {
            lock.unlock();
        }
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
        flushScheduler.scheduleAtFixedRate(this::flushCheck, 1L, 1L, TimeUnit.SECONDS);
    }

    private long getStartupQueueSize() throws IOException {
        return getSegmentPaths(queuePath)
                .mapToLong((p) -> {
                    try {
                        return Files.size(p);
                    } catch (IOException e) {
                        throw new IllegalStateException(e);
                    }
                } )
                .sum();
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
        currentWriter = new RecordIOWriter(queuePath.resolve(String.format(TEMP_FILE_PATTERN, ++currentSegmentIndex)));
        currentQueueSize.increment();
    }

    // Clean up existing temp files - files with an extension of .log.tmp. Either delete them if an existing
    // segment file with the same base name exists, or rename the
    // temp file to the segment file, which can happen when a process ends abnormally
    private void cleanupTempFiles() throws IOException {
        DeadLetterQueueWriter.listFiles(queuePath, ".log.tmp")
                .forEach(this::cleanupTempFile);
    }

    private static Stream<Path> listFiles(Path path, String suffix) throws IOException {
        try(final Stream<Path> files = Files.list(path)) {
            return files.filter(p -> p.toString().endsWith(suffix))
                    .collect(Collectors.toList()).stream();
        }
    }

    // check if there is a corresponding .log file - if yes delete the temp file, if no atomic move the
    // temp file to be a new segment file..
    private void cleanupTempFile(final Path tempFile) {
        String segmentName = tempFile.getFileName().toString().split("\\.")[0];
        Path segmentFile = queuePath.resolve(String.format("%s.log", segmentName));
        try {
            if (Files.exists(segmentFile)) {
                Files.delete(tempFile);
            }
            else {
                SegmentStatus segmentStatus = RecordIOReader.getSegmentStatus(tempFile);
                switch (segmentStatus){
                    case VALID:
                        logger.debug("Moving temp file {} to segment file {}", tempFile, segmentFile);
                        Files.move(tempFile, segmentFile, StandardCopyOption.ATOMIC_MOVE);
                        break;
                    case EMPTY:
                        deleteTemporaryFile(tempFile, segmentName);
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
        } catch (IOException e){
            throw new IllegalStateException("Unable to clean up temp file: " + tempFile, e);
        }
    }

    // Windows can leave files in a "Delete pending" state, where the file presents as existing to certain
    // methods, and not to others, and actively prevents a new file being created with the same file name,
    // throwing AccessDeniedException. This method moves the temporary file to a .del file before
    // deletion, enabling a new temp file to be created in its place.
    private void deleteTemporaryFile(Path tempFile, String segmentName) throws IOException {
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
    }

    private static boolean isWindows(){
        return System.getProperty("os.name").startsWith("Windows");
    }
}
