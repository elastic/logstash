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
import org.logstash.Timestamp;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.nio.file.StandardWatchEventKinds;
import java.nio.file.WatchEvent;
import java.nio.file.WatchKey;
import java.nio.file.WatchService;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.TimeUnit;
import java.util.function.Function;
import java.util.stream.Collectors;

import static java.nio.file.StandardWatchEventKinds.ENTRY_CREATE;
import static java.nio.file.StandardWatchEventKinds.ENTRY_DELETE;
import static org.logstash.common.io.DeadLetterQueueWriter.getSegmentPaths;

public final class DeadLetterQueueReader implements Closeable {
    private static final Logger logger = LogManager.getLogger(DeadLetterQueueReader.class);

    private RecordIOReader currentReader;
    private final Path queuePath;
    private final ConcurrentSkipListSet<Path> segments;
    private final WatchService watchService;

    public DeadLetterQueueReader(Path queuePath) throws IOException {
        this.queuePath = queuePath;
        this.watchService = FileSystems.getDefault().newWatchService();
        this.queuePath.register(watchService, ENTRY_CREATE, ENTRY_DELETE);
        this.segments = new ConcurrentSkipListSet<>((p1, p2) -> {
            Function<Path, Integer> id = (p) -> Integer.parseInt(p.getFileName().toString().split("\\.")[0]);
            return id.apply(p1).compareTo(id.apply(p2));
        });

        segments.addAll(getSegmentPaths(queuePath).collect(Collectors.toList()));
    }

    public void seekToNextEvent(Timestamp timestamp) throws IOException {
        for (Path segment : segments) {
            currentReader = new RecordIOReader(segment);
            byte[] event = currentReader.seekToNextEventPosition(timestamp, (b) -> {
                try {
                    return DLQEntry.deserialize(b).getEntryTime();
                } catch (IOException e) {
                    return null;
                }
            }, Timestamp::compareTo);
            if (event != null) {
                return;
            }
        }
        currentReader.close();
        currentReader = null;
    }

    private long pollNewSegments(long timeout) throws IOException, InterruptedException {
        long startTime = System.currentTimeMillis();
        WatchKey key = watchService.poll(timeout, TimeUnit.MILLISECONDS);
        if (key != null) {
            for (WatchEvent<?> watchEvent : key.pollEvents()) {
                if (watchEvent.kind() == StandardWatchEventKinds.ENTRY_CREATE) {
                    segments.addAll(getSegmentPaths(queuePath).collect(Collectors.toList()));
                }
                key.reset();
            }
        }
        return System.currentTimeMillis() - startTime;
    }

    public DLQEntry pollEntry(long timeout) throws IOException, InterruptedException {
        byte[] bytes = pollEntryBytes(timeout);
        if (bytes == null) {
            return null;
        }
        return DLQEntry.deserialize(bytes);
    }

    byte[] pollEntryBytes() throws IOException, InterruptedException {
        return pollEntryBytes(100);
    }

    byte[] pollEntryBytes(long timeout) throws IOException, InterruptedException {
        long timeoutRemaining = timeout;
        if (currentReader == null) {
            timeoutRemaining -= pollNewSegments(timeout);
            // If no new segments are found, exit
            if (segments.isEmpty()) {
                logger.debug("No entries found: no segment files found in dead-letter-queue directory");
                return null;
            }
            currentReader = new RecordIOReader(segments.first());
        }

        byte[] event = currentReader.readEvent();
        if (event == null && currentReader.isEndOfStream()) {
            if (currentReader.getPath().equals(segments.last())) {
                pollNewSegments(timeoutRemaining);
            } else {
                currentReader.close();
                currentReader = new RecordIOReader(segments.higher(currentReader.getPath()));
                return pollEntryBytes(timeoutRemaining);
            }
        }

        return event;
    }

    public void setCurrentReaderAndPosition(Path segmentPath, long position) throws IOException {
        // If the provided segment Path exist, then set the reader to start from the supplied position
        if (Files.exists(segmentPath)) {
            currentReader = new RecordIOReader(segmentPath);
            currentReader.seekToOffset(position);
        }else{
            // Otherwise, set the current reader to be at the beginning of the next
            // segment.
            Path next = segments.higher(segmentPath);
            if (next != null){
                currentReader = new RecordIOReader(next);
            }
        }
    }

    public Path getCurrentSegment() {
        return currentReader.getPath();
    }

    public long getCurrentPosition() {
        return currentReader.getChannelPosition();
    }

    @Override
    public void close() throws IOException {
        if (currentReader != null) {
            currentReader.close();
        }
    }
}
