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

import org.logstash.ackedqueue.StringElement;

import java.io.IOException;
import java.nio.file.Path;

import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;

public class DeadLetterQueueTestUtils {
    public static final int MB = 1024 * 1024;
    public static final int GB = 1024 * 1024 * 1024;
    public static final int FULL_SEGMENT_FILE_SIZE = 319 * BLOCK_SIZE + 1; // 319 records that fills completely a block plus the 1 byte header of the segment file

    static void writeSomeEventsInOneSegment(int eventCount, Path outputDir) throws IOException {
        Path segmentPath = outputDir.resolve(segmentFileName(0));
        RecordIOWriter writer = new RecordIOWriter(segmentPath);
        for (int j = 0; j < eventCount; j++) {
            writer.writeEvent((new StringElement("" + j)).serialize());
        }
        writer.close();
    }

    static String segmentFileName(int i) {
        return String.format(DeadLetterQueueWriter.SEGMENT_FILE_PATTERN, i);
    }
}
