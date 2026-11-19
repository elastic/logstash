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

package org.logstash.ackedqueue;

/**
 * A failed batch write, possibly before any elements have been written.
 * {@link #getWrittenCount()} is the number of consecutive elements whose writes completed
 * successfully, and therefore the position at which delivery should resume. This applies to
 * both memory and persisted queues; it is not a durability guarantee. A persisted-queue I/O
 * failure can occur after writing the failed element's bytes, so retrying that element may
 * duplicate it. Elements after the reported position have not been attempted.
 */
public final class BatchWriteException extends QueueRuntimeException {

    private static final long serialVersionUID = 1L;

    private final int writtenCount;

    public BatchWriteException(String message, int writtenCount, Throwable cause) {
        super(message, cause);
        this.writtenCount = writtenCount;
    }

    public int getWrittenCount() {
        return writtenCount;
    }
}
