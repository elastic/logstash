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
import java.nio.file.Paths;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.DLQEntry;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.FileLockFactory;
import org.logstash.Timestamp;

import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;

public final class DeadLetterQueueWriter implements Closeable {

    private static final Logger logger = LogManager.getLogger(DeadLetterQueueWriter.class);
    private static final long MAX_SEGMENT_SIZE_BYTES = 10 * 1024 * 1024;

    static final String SEGMENT_FILE_PATTERN = "%d.log";
    static final String LOCK_FILE = ".lock";
    private static final FieldReference DEAD_LETTER_QUEUE_METADATA_KEY =
        FieldReference.from(String.format("%s[dead_letter_queue]", Event.METADATA_BRACKETS));
    private final long maxSegmentSize;
    private final long maxQueueSize;
    private LongAdder currentQueueSize;
    private final Path queuePath;
    private final FileLock lock;
    private volatile RecordIOWriter currentWriter;
    private int currentSegmentIndex;
    private Timestamp lastEntryTimestamp;
    private final AtomicBoolean open = new AtomicBoolean(true);

    public DeadLetterQueueWriter(Path queuePath, long maxSegmentSize, long maxQueueSize) throws IOException {
        this.lock = FileLockFactory.obtainLock(queuePath, LOCK_FILE);
        this.queuePath = queuePath;
        this.maxSegmentSize = maxSegmentSize;
        this.maxQueueSize = maxQueueSize;
        this.currentQueueSize = new LongAdder();
        this.currentQueueSize.add(getStartupQueueSize());

        currentSegmentIndex = getSegmentPaths(queuePath)
                .map(s -> s.getFileName().toString().split("\\.")[0])
                .mapToInt(Integer::parseInt)
                .max().orElse(0);
        nextWriter();
        this.lastEntryTimestamp = Timestamp.now();
    }

    /**
     * Constructor for Writer that uses defaults
     *
     * @param queuePath the path to the dead letter queue segments directory
     * @throws IOException if the size of the file cannot be determined
     */
    public DeadLetterQueueWriter(String queuePath) throws IOException {
        this(Paths.get(queuePath), MAX_SEGMENT_SIZE_BYTES, Long.MAX_VALUE);
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

    private void nextWriter() throws IOException {
        currentWriter = new RecordIOWriter(queuePath.resolve(String.format(SEGMENT_FILE_PATTERN, ++currentSegmentIndex)));
        currentQueueSize.increment();
    }

    static Stream<Path> getSegmentPaths(Path path) throws IOException {
        try(final Stream<Path> files = Files.list(path)) {
            return files.filter(p -> p.toString().endsWith(".log"))
                .collect(Collectors.toList()).stream();
        }
    }

    public synchronized void writeEntry(DLQEntry entry) throws IOException {
        innerWriteEntry(entry);
    }

    public synchronized void writeEntry(Event event, String pluginName, String pluginId, String reason) throws IOException {
        Timestamp entryTimestamp = Timestamp.now();
        if (entryTimestamp.getTime().isBefore(lastEntryTimestamp.getTime())) {
            entryTimestamp = lastEntryTimestamp;
        }
        DLQEntry entry = new DLQEntry(event, pluginName, pluginId, reason);
        innerWriteEntry(entry);
        lastEntryTimestamp = entryTimestamp;
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
            logger.error("cannot write event to DLQ: reached maxQueueSize of " + maxQueueSize);
            return;
        } else if (currentWriter.getPosition() + eventPayloadSize > maxSegmentSize) {
            currentWriter.close();
            nextWriter();
        }
        currentQueueSize.add(currentWriter.writeEvent(record));
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

    @Override
    public void close() {
        if (open.compareAndSet(true, false)) {
            if (currentWriter != null) {
                try {
                    currentWriter.close();
                } catch (Exception e) {
                    logger.debug("Unable to close dlq writer", e);
                }
            }
            releaseLock();
        }
    }

    private void releaseLock() {
        try {
            FileLockFactory.releaseLock(lock);
        } catch (IOException e) {
            logger.debug("Unable to release lock", e);
        }
        try {
            Files.deleteIfExists(queuePath.resolve(LOCK_FILE));
        } catch (IOException e){
            logger.debug("Unable to delete lock file", e);
        }
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
}
