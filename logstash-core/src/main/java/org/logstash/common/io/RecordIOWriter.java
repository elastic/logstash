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

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;

import static org.logstash.common.io.RecordType.COMPLETE;
import static org.logstash.common.io.RecordType.END;
import static org.logstash.common.io.RecordType.MIDDLE;
import static org.logstash.common.io.RecordType.START;

/**
 *
 * File Format
 * | — magic number (4bytes) --|
 *
 * [  32kbyte block....
 *    --- 1 byte RecordHeader Type ---
 *    --- 4 byte RecordHeader Size ---
 *
 * ]
 * [ 32kbyte block...
 *
 *
 *
 * ]
 */
public class RecordIOWriter {

    private final FileChannel channel;
    private int posInBlock;
    private int currentBlockIdx;

    static final int BLOCK_SIZE = 32 * 1024; // package-private for tests
    static final int RECORD_HEADER_SIZE = 5;

    public RecordIOWriter(Path recordsFile) throws IOException {
        this.posInBlock = 0;
        this.currentBlockIdx = 0;
        recordsFile.toFile().createNewFile();
        this.channel = FileChannel.open(recordsFile, StandardOpenOption.WRITE);
    }

    private boolean blockHasSpaceForRecord() {
        return posInBlock + 2 * RECORD_HEADER_SIZE <= BLOCK_SIZE;
    }

    private int remainingInBlock() {
        return BLOCK_SIZE - posInBlock;
    }

    int writeRecordHeader(int size, RecordType type) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(RECORD_HEADER_SIZE);
        buffer.put(type.toByte());
        buffer.putInt(size);
        buffer.rewind();
        return channel.write(buffer);
    }

    private int writeTotalSize(int totalSize) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(4);
        buffer.putInt(totalSize);
        buffer.rewind();
        return channel.write(buffer);
    }

    private RecordType getNextType(ByteBuffer buffer, RecordType previous) {
        boolean fits = buffer.remaining() + 2 * RECORD_HEADER_SIZE < remainingInBlock();
        if (previous == null) {
            return (fits) ? COMPLETE : START;
        }
        if (previous == START || previous == MIDDLE) {
            return (fits) ? END : MIDDLE;
        }
        return null;
    }

    private int getNextRecordSize(ByteBuffer slice, RecordType type) {
        int extraForStart = (type == RecordType.START) ? 4 : 0;
        return Math.min(remainingInBlock() - RECORD_HEADER_SIZE - extraForStart, slice.remaining());
    }

    public long getPosition() throws IOException {
        return channel.position();
    }

    public long writeRecord(byte[] recordArray) throws IOException {
        ByteBuffer recordBuffer = ByteBuffer.wrap(recordArray);
        RecordType nextType = null;
        ByteBuffer slice = recordBuffer.slice();
        long startPosition = channel.position();
        while (slice.hasRemaining()) {
            if (!blockHasSpaceForRecord()) {
                channel.position((++currentBlockIdx) * BLOCK_SIZE);
                posInBlock = 0;
            }
            nextType = getNextType(slice, nextType);
            int originalLimit = slice.limit();
            int nextRecordSize = getNextRecordSize(slice, nextType);
            posInBlock += writeRecordHeader(nextRecordSize, nextType);
            slice.limit(nextRecordSize);
            if (nextType == RecordType.START) {
                posInBlock += writeTotalSize(recordArray.length);
            }
            posInBlock += channel.write(slice);
            slice.limit(originalLimit);
            slice = slice.slice();
        }
        return channel.position() - startPosition;
    }

    public void close() throws IOException {
        channel.close();
    }
}
