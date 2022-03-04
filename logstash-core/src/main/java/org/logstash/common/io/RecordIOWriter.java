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
import java.time.Duration;
import java.time.Instant;
import java.util.OptionalInt;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.zip.CRC32;
import java.util.zip.Checksum;

import static org.logstash.common.io.RecordType.COMPLETE;
import static org.logstash.common.io.RecordType.END;
import static org.logstash.common.io.RecordType.MIDDLE;
import static org.logstash.common.io.RecordType.START;

/**
 *
 * RecordIO File Format: A file that is divided up into equal-sized blocks representing
 * parts of a sequence of Logstash Events so that it is easy to binary-search across to find
 * specific records based on some sort-value.
 *
 * At a high level, each recordIO file contains an initial version byte
 * and then 32kb record block sizes
 *
 * |- VERSION (1 byte) -|- 32kb event block -|- 32kb event block -|...
 *
 * Each 32kb event block contains different record types prepended by their
 * respective record headers
 *
 * |- record header (13 bytes) -|- record type (varlength) -|
 *
 * Record Header:
 *
 * |- record type -|- record size -|- total LS event size -|- checksum -|
 *
 * LS Events are split up into different record types because one event may be larger than the 32kb block
 * allotted. Therefore, we need to cut up the LS Event into different types so that we can more easily piece them
 * together when reading the RecordIO file.
 *
 * There are four different {@link RecordType} definitions:
 *   START: The start of an Event that was broken up into different records
 *   COMPLETE: A record representing the fully serialized LS Event
 *   MIDDLE: A middle record of one or multiple middle records representing a segment of an LS Event that will be proceeded
 *           by a final END record type.
 *   END: The final record segment of an LS Event, the final record representing the end of an LS Event.
 */
public final class RecordIOWriter implements Closeable {

    private final FileChannel channel;
    private int posInBlock;
    private int currentBlockIdx;

    static final int BLOCK_SIZE = 32 * 1024; // package-private for tests
    static final int RECORD_HEADER_SIZE = 13;
    static final int VERSION_SIZE = 1;
    static final char VERSION = '1';

    private Path recordsFile;
    private Instant lastWrite = null;

    public RecordIOWriter(Path recordsFile) throws IOException {
        this.recordsFile = recordsFile;
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
        lastWrite = Instant.now();
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


    public boolean hasWritten(){
        return lastWrite != null;
    }

    public boolean isStale(Duration flushPeriod){
        return hasWritten() && Instant.now().minus(flushPeriod).isAfter(lastWrite);
    }

    public Path getPath(){
        return  this.recordsFile;
    }

    @Override
    public void close() throws IOException {
        channel.close();
    }
}
