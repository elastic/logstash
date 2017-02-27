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
<<<<<<< HEAD
import java.util.OptionalInt;
import java.util.zip.CRC32;
import java.util.zip.Checksum;
=======
>>>>>>> introduce recordio

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
<<<<<<< HEAD
 *    --- 1 byte RecordHeader Type ---
 *    --- 4 byte RecordHeader Size ---
=======
 *    --- 1 byte Record Type ---
 *    --- 4 byte Record Size ---
>>>>>>> introduce recordio
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
<<<<<<< HEAD
=======
    private int numRecords;
>>>>>>> introduce recordio
    private int posInBlock;
    private int currentBlockIdx;

    static final int BLOCK_SIZE = 32 * 1024; // package-private for tests
<<<<<<< HEAD
    static final int RECORD_HEADER_SIZE = 13;
    static final int VERSION_SIZE = 1;
    static final char VERSION = '1';

    public RecordIOWriter(Path recordsFile) throws IOException {
=======
    static final int RECORD_HEADER_SIZE = 5;

    public RecordIOWriter(Path recordsFile) throws IOException {
        this.numRecords = 0;
>>>>>>> introduce recordio
        this.posInBlock = 0;
        this.currentBlockIdx = 0;
        recordsFile.toFile().createNewFile();
        this.channel = FileChannel.open(recordsFile, StandardOpenOption.WRITE);
<<<<<<< HEAD
        this.channel.write(ByteBuffer.wrap(new byte[] { VERSION }));
=======
    }

    private boolean blockHasSpaceForRecord() {
        return posInBlock + RECORD_HEADER_SIZE <= BLOCK_SIZE;
>>>>>>> introduce recordio
    }

    private int remainingInBlock() {
        return BLOCK_SIZE - posInBlock;
    }

<<<<<<< HEAD
    int writeRecordHeader(RecordHeader header) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(RECORD_HEADER_SIZE);
        buffer.put(header.getType().toByte());
        buffer.putInt(header.getSize());
        buffer.putInt(header.getTotalEventSize().orElse(-1));
        buffer.putInt(header.getChecksum());
=======
    private int writeRecordHeader(int size, RecordType type) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(RECORD_HEADER_SIZE);
        buffer.put(type.toByte());
        buffer.putInt(size);
        buffer.rewind();
        return channel.write(buffer);
    }

    private int writeTotalSize(int totalSize) throws IOException {
        ByteBuffer buffer = ByteBuffer.allocate(4);
        buffer.putInt(totalSize);
>>>>>>> introduce recordio
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

<<<<<<< HEAD
=======
    private int getNextRecordSize(ByteBuffer slice, RecordType type) {
        int extraForStart = (type == RecordType.START) ? 4 : 0;
        return Math.min(remainingInBlock() - RECORD_HEADER_SIZE - extraForStart, slice.remaining());
    }

>>>>>>> introduce recordio
    public long getPosition() throws IOException {
        return channel.position();
    }

<<<<<<< HEAD
    public long writeEvent(byte[] eventArray) throws IOException {
        ByteBuffer eventBuffer = ByteBuffer.wrap(eventArray);
        RecordType nextType = null;
        ByteBuffer slice = eventBuffer.slice();
        long startPosition = channel.position();
        while (slice.hasRemaining()) {
            if (posInBlock + RECORD_HEADER_SIZE + 1 > BLOCK_SIZE) {
                channel.position((++currentBlockIdx) * BLOCK_SIZE + VERSION_SIZE);
=======
    public long writeRecord(byte[] recordArray) throws IOException {
        ByteBuffer recordBuffer = ByteBuffer.wrap(recordArray);
        RecordType nextType = null;
        ByteBuffer slice = recordBuffer.slice();
        long startPosition = channel.position();
        while (slice.hasRemaining()) {
            if (!blockHasSpaceForRecord()) {
                channel.position((++currentBlockIdx) * BLOCK_SIZE);
>>>>>>> introduce recordio
                posInBlock = 0;
            }
            nextType = getNextType(slice, nextType);
            int originalLimit = slice.limit();
<<<<<<< HEAD
            int nextRecordSize = Math.min(remainingInBlock() - RECORD_HEADER_SIZE, slice.remaining());
            OptionalInt optTotalSize = (nextType == RecordType.START) ? OptionalInt.of(eventArray.length) : OptionalInt.empty();
            slice.limit(nextRecordSize);

            Checksum checksum = new CRC32();
            checksum.update(slice.array(), slice.arrayOffset() + slice.position(), nextRecordSize);
            posInBlock += writeRecordHeader(
                    new RecordHeader(nextType, nextRecordSize, optTotalSize, (int) checksum.getValue()));
            posInBlock += channel.write(slice);

=======
            int nextRecordSize = getNextRecordSize(slice, nextType);
            posInBlock += writeRecordHeader(nextRecordSize, nextType);
            slice.limit(nextRecordSize);
            if (nextType == RecordType.START) {
                posInBlock += writeTotalSize(recordArray.length);
            }
            posInBlock += channel.write(slice);
>>>>>>> introduce recordio
            slice.limit(originalLimit);
            slice = slice.slice();
        }
        return channel.position() - startPosition;
    }

    public void close() throws IOException {
        channel.close();
    }
}
