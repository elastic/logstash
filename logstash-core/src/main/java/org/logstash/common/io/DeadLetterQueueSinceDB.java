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

package org.logstash.common.io;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Comparator;
import java.util.Optional;

import static org.logstash.common.io.DeadLetterQueueWriter.getSegmentPaths;

public class DeadLetterQueueSinceDB {

    private static final Logger logger = LogManager.getLogger(DeadLetterQueueSinceDB.class);

    private final static char VERSION = '1';
    private Path sinceDb;
    private Path currentSegment;
    private long offset;

    private DeadLetterQueueSinceDB(Path sinceDb, Path currentSegment, long offset) {
        this.sinceDb = sinceDb;
        this.currentSegment = currentSegment;
        this.offset = offset;
    }

    public static DeadLetterQueueSinceDB load(Path queuePath) throws IOException {
        if (queuePath == null) {
            throw new IllegalArgumentException("queuePath can't be null");
        }
        Path sinceDbPath = queuePath.resolve("sincedb");
        if (!Files.exists(sinceDbPath)) {
            return startSegment(sinceDbPath, queuePath);
        }

        byte[] bytes = Files.readAllBytes(sinceDbPath);
        if (bytes.length == 0) {
            return startSegment(sinceDbPath, queuePath);
        }

        ByteBuffer buffer = ByteBuffer.wrap(bytes);
        verifyVersion(buffer);
        Path segmentPath = decodePath(buffer);
        long offset = buffer.getLong();
        return new DeadLetterQueueSinceDB(sinceDbPath, segmentPath, offset);
    }

    private static void verifyVersion(ByteBuffer buffer) {
        char version = buffer.getChar();
        if (VERSION != version) {
            throw new RuntimeException("Sincedb version:" + version + " does not match: " + VERSION);
        }
    }

    private static Path decodePath(ByteBuffer buffer) {
        int segmentPathStringLength = buffer.getInt();
        byte[] segmentPathBytes = new byte[segmentPathStringLength];
        buffer.get(segmentPathBytes);
        return Paths.get(new String(segmentPathBytes));
    }

    /**
     * Return sincedb instance pointing to the start of the first segment, is present.
     * If no segment files are present, the DLQ is empty and is going to be populated by next {@link #flush() flush}.
     * */
    private static DeadLetterQueueSinceDB startSegment(Path sinceDbPath, Path queuePath) throws IOException {
        Path firstSegment = findFirstSegment(queuePath)
                .orElse(null);
        return new DeadLetterQueueSinceDB(sinceDbPath, firstSegment, 0L);
    }

    private static Optional<Path> findFirstSegment(Path queuePath) throws IOException {
        return getSegmentPaths(queuePath)
                .min(Comparator.comparingInt(DeadLetterQueueUtils::extractSegmentId));
    }

    public void flush() {
        if (currentSegment == null) {
            return;
        }
        logger.debug("Flushing DLQ last read position");
        String path = currentSegment.toAbsolutePath().toString();
        ByteBuffer buffer = ByteBuffer.allocate(path.length() + 1 + 64);
        buffer.putChar(VERSION);
        buffer.putInt(path.length());
        buffer.put(path.getBytes());
        buffer.putLong(offset);
        try {
            Files.write(sinceDb, buffer.array());
        } catch (IOException e) {
            logger.error("failed to write DLQ offset state to " + sinceDb, e);
        }
    }

    private void updatePosition(Path segment, long offset) {
        this.currentSegment = segment;
        this.offset = offset;
    }

    public void updatePosition(DeadLetterQueueReader reader) {
        reader.getCurrentSegmentPath()
                .ifPresent(segment -> updatePosition(segment, reader.getCurrentPosition()));
    }

    public Path getCurrentSegment() {
        return currentSegment;
    }

    public long getOffset() {
        return offset;
    }
}
