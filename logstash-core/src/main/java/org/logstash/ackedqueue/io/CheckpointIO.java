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


package org.logstash.ackedqueue.io;

import org.logstash.ackedqueue.Checkpoint;
import java.io.IOException;

/**
 * Internal API to access checkpoint stored in files.
 * */
public interface CheckpointIO {

    // @return Checkpoint the written checkpoint object
    Checkpoint write(String fileName, int pageNum, int firstUnackedPageNum, long firstUnackedSeqNum, long minSeqNum, int elementCount) throws IOException;

    void write(String fileName, Checkpoint checkpoint) throws IOException;

    Checkpoint read(String fileName) throws IOException;

    void purge(String fileName) throws IOException;

    // @return the head page checkpoint file name
    String headFileName();

    // @return the tail page checkpoint file name for given page number
    String tailFileName(int pageNum);
}
