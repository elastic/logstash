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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.DLQEntry;
import org.logstash.FileLockFactory;
import org.logstash.LockException;
import org.logstash.Timestamp;

import java.io.IOException;
import java.nio.channels.FileLock;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.nio.file.StandardOpenOption;
import java.nio.file.StandardWatchEventKinds;
import java.nio.file.WatchEvent;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.nio.file.attribute.FileTime;
import java.util.Comparator;
import java.util.LongSummaryStatistics;
import java.util.NoSuchElementException;
import java.util.Optional;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.LongAdder;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static java.nio.file.StandardWatchEventKinds.ENTRY_CREATE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_DELETE;
import static org.logstash.common.io.DeadLetterQueueUtils.listSegmentPaths;

/**
 * Class responsible to read messages from DLQ and manage segments deletion.
 *
 * This class is instantiated and used by DeadLetterQueue input plug to retrieve the messages from DLQ.
 * When the plugin is configured to clean consumed segments, it also deletes the segments that are processed.
 * The deletion of segments could concur with the {@link org.logstash.common.io.DeadLetterQueueWriter} age and
 * storage policies. This means that writer side's DLQ size metric needs to be updated everytime a segment is removed.
 * Given that reader and writer sides of DLQ can be executed on different Logstash process, the reader needs to notify
 * the writer, to do this, the reader creates a notification file that's monitored by the writer.
 * */
public final class DeadLetterQueueReader implements Closeable {
    private static final Logger logger = LogManager.getLogger(DeadLetterQueueReader.class);
    public static final String DELETED_SEGMENT_PREFIX = ".deleted_segment";

    private RecordIOReader currentReader;
    private final Path queuePath;
    private final SegmentListener segmentCallback;
    private final ConcurrentSkipListSet<Path> segments;
    private final WatchService watchService;
    private RecordIOReader lastConsumedReader;
    private final LongAdder consumedEvents = new LongAdder();
    private final LongAdder consumedSegments = new LongAdder();

    // config settings
    private final boolean cleanConsumed;
    private FileLock fileLock;

    public DeadLetterQueueReader(Path queuePath) throws IOException {
        this(queuePath, false, null);
    }

    public DeadLetterQueueReader(Path queuePath, boolean cleanConsumed, SegmentListener segmentCallback) throws IOException {
        this.queuePath = queuePath;
        this.watchService = FileSystems.getDefault().newWatchService();
        this.queuePath.register(watchService, ENTRY_CREATE, ENTRY_DELETE);
        this.segments = new ConcurrentSkipListSet<>(
                Comparator.comparingInt(DeadLetterQueueUtils::extractSegmentId)
        );
        segments.addAll(listSegmentPaths(queuePath)
                .filter(p -> p.toFile().length() > 1) // take the files that have content to process
                .collect(Collectors.toList()));
        this.cleanConsumed = cleanConsumed;
        if (cleanConsumed && segmentCallback == null) {
            throw new IllegalArgumentException("When cleanConsumed is enabled must be passed also a valid segment listener");
        }
        this.segmentCallback = segmentCallback;
        this.lastConsumedReader = null;
        if (cleanConsumed) {
            // force single DLQ reader when clean consumed is requested
            try {
                fileLock = FileLockFactory.obtainLock(queuePath, "dlq_reader.lock");
            } catch (LockException ex) {
                throw new LockException("Existing `dlg_reader.lock` file in [" + queuePath + "]. Only one DeadLetterQueueReader with `cleanConsumed` set is allowed per Dead Letter Queue.", ex);
            }
        }
    }

    public void seekToNextEvent(Timestamp timestamp) throws IOException {
        for (Path segment : segments) {
            Optional<RecordIOReader> optReader = openSegmentReader(segment);
            if (!optReader.isPresent()) {
                continue;
            }
            currentReader = optReader.get();

            byte[] event = currentReader.seekToNextEventPosition(timestamp, DeadLetterQueueReader::extractEntryTimestamp, Timestamp::compareTo);
            if (event != null) {
                return;
            }
        }
        if (currentReader != null) {
            currentReader.close();
            currentReader = null;
        }
    }

    /**
     * Opens the segment reader for the given path.
     * Side effect: Will attempt to remove the given segment from the list of active
     *              segments if segment is not found.
     * @param segment Path to segment File
     * @return Optional containing a RecordIOReader if the segment exists
     * @throws IOException if any IO error happens during file management
     */
    private Optional<RecordIOReader> openSegmentReader(Path segment) throws IOException {
        if (!Files.exists(segment)) {
            // file was deleted by upstream process and segments list wasn't yet updated
            segments.remove(segment);
            return Optional.empty();
        }

        try {
            return Optional.of(new RecordIOReader(segment));
        } catch (NoSuchFileException ex) {
            logger.debug("Segment file {} was deleted by DLQ writer during DLQ reader opening", segment);
            // file was deleted by upstream process and segments list wasn't yet updated
            segments.remove(segment);
            return Optional.empty();
        }
    }

    private static Timestamp extractEntryTimestamp(byte[] serialized) {
        try {
            return DLQEntry.deserialize(serialized).getEntryTime();
        } catch (IOException e) {
            throw new IllegalStateException(e);
        }
    }

    private long pollNewSegments(long timeout) throws IOException, InterruptedException {
        long startTime = System.currentTimeMillis();
        WatchKey key = watchService.poll(timeout, TimeUnit.MILLISECONDS);
        if (key != null) {
            pollSegmentsOnWatch(key);
        }
        return System.currentTimeMillis() - startTime;
    }

    private void pollNewSegments() throws IOException {
        WatchKey key = watchService.poll();
        if (key != null) {
            pollSegmentsOnWatch(key);
        }
    }

    private void pollSegmentsOnWatch(WatchKey key) throws IOException {
        for (WatchEvent<?> watchEvent : key.pollEvents()) {
            if (watchEvent.kind() == StandardWatchEventKinds.ENTRY_CREATE) {
                segments.addAll(listSegmentPaths(queuePath).collect(Collectors.toList()));
            } else if (watchEvent.kind() == StandardWatchEventKinds.ENTRY_DELETE) {
                final int oldSize = segments.size();
                segments.clear();
                segments.addAll(listSegmentPaths(queuePath).collect(Collectors.toList()));
                logger.debug("Notified of segment removal, switched from {} to {} segments", oldSize, segments.size());
            }
            key.reset();
        }
    }

    public DLQEntry pollEntry(long timeout) throws IOException, InterruptedException {
        byte[] bytes = pollEntryBytes(timeout);
        if (bytes == null) {
            return null;
        }
        return DLQEntry.deserialize(bytes);
    }

    // package-private for test
    byte[] pollEntryBytes() throws IOException, InterruptedException {
        return pollEntryBytes(100);
    }

    private byte[] pollEntryBytes(long timeout) throws IOException, InterruptedException {
        long timeoutRemaining = timeout;
        if (currentReader == null) {
            timeoutRemaining -= pollNewSegments(timeout);
            // If no new segments are found, exit
            if (segments.isEmpty()) {
                logger.debug("No entries found: no segment files found in dead-letter-queue directory");
                return null;
            }
            Optional<RecordIOReader> optReader;
            do {
                final Path firstSegment;
                try {
                    firstSegment = segments.first();
                } catch (NoSuchElementException ex) {
                    // all elements were removed after the empty check
                    logger.debug("No entries found: no segment files found in dead-letter-queue directory");
                    return null;
                }

                optReader = openSegmentReader(firstSegment);
                if (optReader.isPresent()) {
                    currentReader = optReader.get();
                }
            } while (!optReader.isPresent());
        }

        byte[] event = currentReader.readEvent();
        if (event == null && currentReader.isEndOfStream()) {
            if (consumedAllSegments()) {
                pollNewSegments(timeoutRemaining);
            } else {
                currentReader.close();
                if (cleanConsumed) {
                    lastConsumedReader = currentReader;
                }
                Optional<RecordIOReader> optReader = openNextExistingReader(currentReader.getPath());
                if (!optReader.isPresent()) {
                    // segments were all already deleted files, do a poll
                    pollNewSegments(timeoutRemaining);
                } else {
                    currentReader = optReader.get();
                    return pollEntryBytes(timeoutRemaining);
                }
            }
        }

        return event;
    }

    /**
     * Acknowledge last read event, must match every {@code #pollEntry} call.
     * */
    public void markForDelete() {
        if (!cleanConsumed) {
            // ack-event is useful only when clean consumed is enabled.
            return;
        }
        if (lastConsumedReader == null) {
            // no reader to a consumed segment is present
            return;
        }

        segmentCallback.segmentCompleted();

        Path lastConsumedSegmentPath = lastConsumedReader.getPath();

        // delete also the older segments in case of multiple segments were consumed
        // before the invocation of the mark method.
        try {
            removeSegmentsBefore(lastConsumedSegmentPath);
        } catch (IOException ex) {
            logger.warn("Problem occurred in cleaning the segments older than {} ", lastConsumedSegmentPath, ex);
        }

        // delete segment file only after current reader is closed.
        // closing happens in pollEntryBytes method when it identifies the reader is at end of stream
        final Optional<Long> deletedEvents = deleteSegment(lastConsumedSegmentPath);
        if (deletedEvents.isPresent()) {
            // update consumed metrics
            consumedEvents.add(deletedEvents.get());
            consumedSegments.increment();
        }

        // publish the metrics to the listener
        segmentCallback.segmentsDeleted(consumedSegments.intValue(), consumedEvents.longValue());

        lastConsumedReader = null;
    }

    private boolean consumedAllSegments() {
        try {
            return currentReader.getPath().equals(segments.last());
        } catch (NoSuchElementException ex) {
            // last segment was removed while processing
            logger.debug("No last segment found, poll for new segments");
            return true;
        }
    }

    private Path nextExistingSegmentFile(Path currentSegmentPath) {
        Path nextExpectedSegment;
        boolean skip;
        do {
            nextExpectedSegment = segments.higher(currentSegmentPath);
            if (nextExpectedSegment != null && !Files.exists(nextExpectedSegment)) {
                segments.remove(nextExpectedSegment);
                skip = true;
            } else {
                skip = false;
            }
        } while (skip);
        return nextExpectedSegment;
    }

    public void setCurrentReaderAndPosition(Path segmentPath, long position) throws IOException {
        if (cleanConsumed) {
            removeSegmentsBefore(segmentPath);
        }

        // If the provided segment Path exist, then set the reader to start from the supplied position
        Optional<RecordIOReader> optReader = openSegmentReader(segmentPath);
        if (optReader.isPresent()) {
            currentReader = optReader.get();
            currentReader.seekToOffset(position);
            return;
        }
        // Otherwise, set the current reader to be at the beginning of the next
        // segment.
        optReader = openNextExistingReader(segmentPath);
        if (optReader.isPresent()) {
            currentReader = optReader.get();
            return;
        }

        pollNewSegments();

        // give a second try after a re-load of segments from filesystem
        openNextExistingReader(segmentPath)
                .ifPresent(reader -> currentReader = reader);
    }

    private void removeSegmentsBefore(Path validSegment) throws IOException {
        final Comparator<Path> fileTimeAndName = ((Comparator<Path>) this::compareByFileTimestamp)
                .thenComparingInt(DeadLetterQueueUtils::extractSegmentId);

        try (final Stream<Path> segmentFiles = listSegmentPaths(queuePath)) {
            LongSummaryStatistics deletionStats = segmentFiles.filter(p -> fileTimeAndName.compare(p, validSegment) < 0)
                    .map(this::deleteSegment)
                    .map(o -> o.orElse(0L))
                    .mapToLong(Long::longValue)
                    .summaryStatistics();

            // update consumed metrics
            consumedSegments.add(deletionStats.getCount());
            consumedEvents.add(deletionStats.getSum());
        }

        createSegmentRemovalFile(validSegment);
    }

    /**
     * Create a notification file to signal to the upstream pipeline to update its metrics
     * */
    private void createSegmentRemovalFile(Path lastDeletedSegment) {
        final Path notificationFile = queuePath.resolve(DELETED_SEGMENT_PREFIX);
        byte[] content = (lastDeletedSegment + "\n").getBytes(StandardCharsets.UTF_8);
        if (Files.exists(notificationFile)) {
            updateToExistingNotification(notificationFile, content);
            return;
        }
        createNotification(notificationFile, content);
    }

    private void createNotification(Path notificationFile, byte[] content) {
        try {
            final Path tmpNotificationFile = Files.createFile(queuePath.resolve(DELETED_SEGMENT_PREFIX + ".tmp"));
            Files.write(tmpNotificationFile, content, StandardOpenOption.APPEND);
            Files.move(tmpNotificationFile, notificationFile, StandardCopyOption.ATOMIC_MOVE);
            logger.debug("Recreated notification file {}", notificationFile);
        } catch (IOException e) {
            logger.error("Can't create file to notify deletion of segments from DLQ reader in path {}", notificationFile, e);
        }
    }

    private static void updateToExistingNotification(Path notificationFile, byte[] contentToAppend) {
        try {
            Files.write(notificationFile, contentToAppend, StandardOpenOption.APPEND);
            logger.debug("Updated existing notification file {}", notificationFile);
        } catch (IOException e) {
            logger.error("Can't update file to notify deletion of segments from DLQ reader in path {}", notificationFile, e);
        }
        logger.debug("Notification segments delete file already exists {}", notificationFile);
    }

    private int compareByFileTimestamp(Path p1, Path p2) {
        final Optional<FileTime> timestampResult1 = readLastModifiedTime(p1);
        final Optional<FileTime> timestampResult2 = readLastModifiedTime(p2);

        // if one of the readLastModifiedTime encountered a file not found error or generic IO error,
        // consider them equals and fallback to the other comparator
        if (!timestampResult1.isPresent() || !timestampResult2.isPresent()) {
            return 0;
        }

        return timestampResult1.get().compareTo(timestampResult2.get());
    }

    /**
     * Builder method. Read the timestamp if file on path p is present.
     * When the file
     * */
    private static Optional<FileTime> readLastModifiedTime(Path p) {
        try {
            return Optional.of(Files.getLastModifiedTime(p));
        } catch (NoSuchFileException fileNotFoundEx) {
            logger.debug("File {} doesn't exist", p);
            return Optional.empty();
        } catch (IOException ex) {
            logger.warn("Error reading file's timestamp for {}", p, ex);
            return Optional.empty();
        }
    }

    /**
     * Remove the segment from internal tracking data structures and physically delete the corresponding
     * file from filesystem.
     *
     * @return the number events contained in the removed segment, empty if a problem happened during delete.
     * */
    private Optional<Long> deleteSegment(Path segment) {
        segments.remove(segment);
        try {
            long eventsInSegment = DeadLetterQueueUtils.countEventsInSegment(segment);
            Files.delete(segment);
            logger.debug("Deleted segment {}", segment);
            return Optional.of(eventsInSegment);
        } catch (NoSuchFileException fileNotFoundEx) {
            logger.debug("Expected file segment {} was already removed by a writer", segment);
            return Optional.empty();
        } catch (IOException ex) {
            logger.warn("Problem occurred in cleaning the segment {} after a repositioning", segment, ex);
            return Optional.empty();
        }
    }

    private Optional<RecordIOReader> openNextExistingReader(Path segmentPath) throws IOException {
        Path next;
        while ( (next = nextExistingSegmentFile(segmentPath)) != null ) {
            Optional<RecordIOReader> optReader = openSegmentReader(next);
            if (optReader.isPresent()) {
                return optReader;
            }
        }
        return Optional.empty();
    }

    public Path getCurrentSegment() {
        return currentReader.getPath();
    }

    public long getCurrentPosition() {
        return currentReader.getChannelPosition();
    }

    long getConsumedEvents() {
        return consumedEvents.longValue();
    }

    int getConsumedSegments() {
        return consumedSegments.intValue();
    }

    @Override
    public void close() throws IOException {
        try {
            if (currentReader != null) {
                currentReader.close();
            }
            this.watchService.close();
        } finally {
            if (this.cleanConsumed) {
                FileLockFactory.releaseLock(this.fileLock);
            }
        }
    }
}
