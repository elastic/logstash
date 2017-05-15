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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.DLQEntry;
import org.logstash.Event;
import org.logstash.Timestamp;

import java.io.IOException;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.channels.OverlappingFileLockException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.stream.Stream;

import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;

public class DeadLetterQueueWriter {

    private static final Logger logger = LogManager.getLogger(DeadLetterQueueWriter.class);
    private static final long MAX_SEGMENT_SIZE_BYTES = 10 * 1024 * 1024;

    static final String SEGMENT_FILE_PATTERN = "%d.log";
    static final String LOCK_FILE = ".lock";
    private final long maxSegmentSize;
    private final long maxQueueSize;
    private final Path queuePath;
    private final FileLock lock;
    private RecordIOWriter currentWriter;
    private long currentQueueSize;
    private int currentSegmentIndex;
    private Timestamp lastEntryTimestamp;
    private boolean open;

    public DeadLetterQueueWriter(Path queuePath, long maxSegmentSize, long maxQueueSize) throws IOException {
        // ensure path exists, create it otherwise.
        Files.createDirectories(queuePath);
        // check that only one instance of the writer is open in this configured path
        Path lockFilePath = queuePath.resolve(LOCK_FILE);
        boolean isNewlyCreated = lockFilePath.toFile().createNewFile();
        FileChannel channel = FileChannel.open(lockFilePath, StandardOpenOption.WRITE);
        try {
            this.lock = channel.lock();
        } catch (OverlappingFileLockException e) {
            if (isNewlyCreated) {
                logger.warn("Previous Dead Letter Queue Writer was not closed safely.");
            }
            throw new RuntimeException("uh oh, someone else is writing to this dead-letter queue");
        }

        this.queuePath = queuePath;
        this.maxSegmentSize = maxSegmentSize;
        this.maxQueueSize = maxQueueSize;
        this.currentQueueSize = getStartupQueueSize();

        currentSegmentIndex = getSegmentPaths(queuePath)
                .map(s -> s.getFileName().toString().split("\\.")[0])
                .mapToInt(Integer::parseInt)
                .max().orElse(0);
        this.currentWriter = nextWriter();
        this.lastEntryTimestamp = Timestamp.now();
        this.open = true;
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
                        return 0L;
                    }
                } )
                .sum();
    }

    private RecordIOWriter nextWriter() throws IOException {
        return new RecordIOWriter(queuePath.resolve(String.format(SEGMENT_FILE_PATTERN, ++currentSegmentIndex)));
    }

    static Stream<Path> getSegmentPaths(Path path) throws IOException {
        return Files.list(path).filter((p) -> p.toString().endsWith(".log"));
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
        byte[] record = entry.serialize();
        int eventPayloadSize = RECORD_HEADER_SIZE + record.length;
        if (currentQueueSize + eventPayloadSize > maxQueueSize) {
            logger.error("cannot write event to DLQ: reached maxQueueSize of " + maxQueueSize);
            return;
        } else if (currentWriter.getPosition() + eventPayloadSize > maxSegmentSize) {
            currentWriter.close();
            currentWriter = nextWriter();
        }
        currentQueueSize += currentWriter.writeEvent(record);
    }


    public synchronized void close() throws IOException {
        this.lock.release();
        if (currentWriter != null) {
            currentWriter.close();
        }
        Files.deleteIfExists(queuePath.resolve(LOCK_FILE));
        open = false;
    }

    public boolean isOpen() {
        return open;
    }
}
