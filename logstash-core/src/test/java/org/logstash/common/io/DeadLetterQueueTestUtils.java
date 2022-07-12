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

import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION_SIZE;

public class DeadLetterQueueTestUtils {
    public static final int MB = 1024 * 1024;
    public static final int GB = 1024 * 1024 * 1024;
    public static final int FULL_SEGMENT_FILE_SIZE = 319 * BLOCK_SIZE + VERSION_SIZE; // 319 records that fills completely a block plus the 1 byte header of the segment file
}
