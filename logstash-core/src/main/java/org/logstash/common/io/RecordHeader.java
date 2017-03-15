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

import java.nio.ByteBuffer;
import java.util.OptionalInt;

public class RecordHeader {
    private final RecordType type;
    private final int size;
    private final OptionalInt totalEventSize;

    RecordHeader(RecordType type, int size, OptionalInt totalEventSize) {
        this.type = type;
        this.size = size;
        this.totalEventSize = totalEventSize;
    }

    public RecordType getType() {
        return type;
    }

    public int getSize() {
        return size;
    }

    public OptionalInt getTotalEventSize() {
        return totalEventSize;
    }

    public static RecordHeader get(ByteBuffer currentBlock) {
        RecordType type = RecordType.fromByte(currentBlock.get());

        if (type == null) {
            return null;
        }

        final int size = currentBlock.getInt();
        final OptionalInt totalEventSize;

        if (RecordType.START.equals(type)) {
            totalEventSize = OptionalInt.of(currentBlock.getInt());
        } else if (RecordType.COMPLETE.equals(type)) {
            totalEventSize = OptionalInt.of(size);
        } else {
            totalEventSize = OptionalInt.empty();
        }

        return new RecordHeader(type, size, totalEventSize);
    }
}
