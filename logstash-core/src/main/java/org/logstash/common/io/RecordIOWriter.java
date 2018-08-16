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
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.OptionalInt;
import java.util.zip.CRC32;
import java.util.zip.Checksum;

import static org.logstash.common.io.RecordType.COMPLETE;
import static org.logstash.common.io.RecordType.END;
import static org.logstash.common.io.RecordType.MIDDLE;
import static org.logstash.common.io.RecordType.START;

/**
 *
 * File Format
 * | - magic number (4bytes) --|
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
public final class RecordIOWriter implements Closeable {

    private final FileChannel channel;
    private int posInBlock;
    private int currentBlockIdx;

    static final int BLOCK_SIZE = 32 * 1024; // package-private for tests
    static final int RECORD_HEADER_SIZE = 13;
    static final int VERSION_SIZE = 1;
    static final char VERSION = '1';

    public RecordIOWriter(Path recordsFile) throws IOException {
        this.posInBlock = 0;
        this.currentBlockIdx = 0;
        recordsFile.toFile().createNewFile();
        this.channel = FileChannel.open(recordsFile, StandardOpenOption.WRITE);
        this.channel.write(ByteBuffer.wrap(new byte[] { VERSION }));
    }

    private int remainingInBlock() {
        return BLOCK_SIZE - posInBlock;
    }

    int writeRecordHeader(RecordHeader header) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(RECORD_HEADER_SIZE);
        buffer.put(header.getType().toByte());
        buffer.putInt(header.getSize());
        buffer.putInt(header.getTotalEventSize().orElse(-1));
        buffer.putInt(header.getChecksum());
        buffer.rewind();
        return channel.write(buffer);
    }

    private RecordType getNextType(ByteBuffer buffer, RecordType previous) {
        boolean fits = buffer.remaining() + RECORD_HEADER_SIZE < remainingInBlock();
        if (previous == null) {
            return (fits) ? COMPLETE : START;
        }
        if (previous == START || previous == MIDDLE) {
            return (fits) ? END : MIDDLE;
        }
        return null;
    }

    public long getPosition() throws IOException {
        return channel.position();
    }

    public long writeEvent(byte[] eventArray) throws IOException {
        ByteBuffer eventBuffer = ByteBuffer.wrap(eventArray);
        RecordType nextType = null;
        ByteBuffer slice = eventBuffer.slice();
        long startPosition = channel.position();
        while (slice.hasRemaining()) {
            if (posInBlock + RECORD_HEADER_SIZE + 1 > BLOCK_SIZE) {
                channel.position((++currentBlockIdx) * BLOCK_SIZE + VERSION_SIZE);
                posInBlock = 0;
            }
            nextType = getNextType(slice, nextType);
            int originalLimit = slice.limit();
            int nextRecordSize = Math.min(remainingInBlock() - RECORD_HEADER_SIZE, slice.remaining());
            OptionalInt optTotalSize = (nextType == RecordType.START) ? OptionalInt.of(eventArray.length) : OptionalInt.empty();
            slice.limit(nextRecordSize);

            Checksum checksum = new CRC32();
            checksum.update(slice.array(), slice.arrayOffset() + slice.position(), nextRecordSize);
            posInBlock += writeRecordHeader(
                    new RecordHeader(nextType, nextRecordSize, optTotalSize, (int) checksum.getValue()));
            posInBlock += channel.write(slice);

            slice.limit(originalLimit);
            slice = slice.slice();
        }
        return channel.position() - startPosition;
    }

    @Override
    public void close() throws IOException {
        channel.close();
    }
}
