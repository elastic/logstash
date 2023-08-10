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
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Comparator;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.logstash.common.io.RecordIOWriter.*;

class DeadLetterQueueUtils {

    private static final Logger logger = LogManager.getLogger(DeadLetterQueueUtils.class);

    static int extractSegmentId(Path p) {
        return Integer.parseInt(p.getFileName().toString().split("\\.log")[0]);
    }

    static Stream<Path> listFiles(Path path, String suffix) throws IOException {
        try(final Stream<Path> files = Files.list(path)) {
            return files.filter(p -> p.toString().endsWith(suffix))
                    .collect(Collectors.toList()).stream();
        }
    }

    static Stream<Path> listSegmentPaths(Path path) throws IOException {
        return listFiles(path, ".log");
    }

    static Stream<Path> listSegmentPathsSortedBySegmentId(Path path) throws IOException {
        return listSegmentPaths(path)
                .sorted(Comparator.comparingInt(DeadLetterQueueUtils::extractSegmentId));
    }

    /**
     * Count the number of 'c' and 's' records in segment.
     * An event can't be bigger than the segments so in case of records split across multiple event blocks,
     * the segment has to contain both the start 's' record, all the middle 'm' up to the end 'e' records.
     * */
    @SuppressWarnings("fallthrough")
    static long countEventsInSegment(Path segment) throws IOException {
        try (FileChannel channel = FileChannel.open(segment, StandardOpenOption.READ)) {
            // verify minimal segment size
            if (channel.size() < VERSION_SIZE + RECORD_HEADER_SIZE) {
                return 0L;
            }

            // skip the DLQ version byte
            channel.position(1);
            int posInBlock = 0;
            int currentBlockIdx = 0;
            long countedEvents = 0;
            do {
                ByteBuffer headerBuffer = ByteBuffer.allocate(RECORD_HEADER_SIZE);
                long startPosition = channel.position();
                // if record header can't be fully contained in the block, align to the next
                if (posInBlock + RECORD_HEADER_SIZE + 1 > BLOCK_SIZE) {
                    channel.position((++currentBlockIdx) * BLOCK_SIZE + VERSION_SIZE);
                    posInBlock = 0;
                }

                channel.read(headerBuffer);
                headerBuffer.flip();
                RecordHeader recordHeader = RecordHeader.get(headerBuffer);
                if (recordHeader == null) {
                    // continue with next record, skipping this
                    logger.error("Can't decode record header, position {} current post {} current events count {}", startPosition, channel.position(), countedEvents);
                } else {
                    switch (recordHeader.getType()) {
                        case START:
                        case COMPLETE:
                            countedEvents++;
                        case MIDDLE:
                        case END: {
                            channel.position(channel.position() + recordHeader.getSize());
                            posInBlock += RECORD_HEADER_SIZE + recordHeader.getSize();
                        }
                    }
                }
            } while (channel.position() < channel.size());

            return countedEvents;
        }
    }
}
