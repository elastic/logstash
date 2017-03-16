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
import java.util.zip.CRC32;
import java.util.zip.Checksum;

import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION;
import static org.logstash.common.io.RecordIOWriter.VERSION_SIZE;

/**
 */
public class RecordIOReader {

    private final FileChannel channel;
    private final ByteBuffer currentBlock;
    private int currentBlockSizeReadFromChannel;
    private final Path path;

    public RecordIOReader(Path path) throws IOException {
        this.path = path;
        this.channel = FileChannel.open(path, StandardOpenOption.READ);
        this.currentBlock = ByteBuffer.allocate(BLOCK_SIZE);
        this.currentBlockSizeReadFromChannel = 0;
        ByteBuffer versionBuffer = ByteBuffer.allocate(1);
        this.channel.read(versionBuffer);
        versionBuffer.rewind();
        if (versionBuffer.get() != VERSION) {
            throw new RuntimeException("Invalid file. check version");
        }
    }

    public Path getPath() {
        return path;
    }

    public void seekToBlock(int bid) throws IOException {
        currentBlock.rewind();
        currentBlockSizeReadFromChannel = 0;
        channel.position(bid * BLOCK_SIZE + VERSION_SIZE);
    }

    /**
     *
     * @param rewind
     * @throws IOException
     */
    void consumeBlock(boolean rewind) throws IOException {
        if (rewind) {
            currentBlockSizeReadFromChannel = 0;
            currentBlock.rewind();
        } else if (currentBlockSizeReadFromChannel == BLOCK_SIZE) {
            // already read enough, no need to read more
            return;
        }
        int originalPosition = currentBlock.position();
        int read = channel.read(currentBlock);
        currentBlockSizeReadFromChannel += (read > 0) ? read : 0;
        currentBlock.position(originalPosition);
    }

    /**
     * basically, is last block
     * @return
     */
    public boolean isEndOfStream() {
        return currentBlockSizeReadFromChannel < BLOCK_SIZE;
    }

    /**
     *
     */
     int seekToStartOfEventInBlock() throws IOException {
         while (true) {
             RecordType type = RecordType.fromByte(currentBlock.array()[currentBlock.arrayOffset() + currentBlock.position()]);
             if (RecordType.COMPLETE.equals(type) || RecordType.START.equals(type)) {
                 return currentBlock.position();
             } else if (RecordType.END.equals(type)) {
                 RecordHeader header = RecordHeader.get(currentBlock);
                 currentBlock.position(currentBlock.position() + header.getSize());
             } else {
                 return -1;
             }
         }
    }

    /**
     *
     * @return true if ready to read event, false otherwise
     * @throws IOException
     */
    boolean consumeToStartOfEvent() throws IOException {
        // read and seek to start of event
        consumeBlock(false);
        while (true) {
            int eventStartPosition = seekToStartOfEventInBlock();
            if (eventStartPosition < 0) {
                if (isEndOfStream()) {
                    return false;
                } else {
                    consumeBlock(true);
                }
            } else {
                return true;
            }
        }
    }

    private void maybeRollToNextBlock() throws IOException {
        // check block position state
        if (currentBlock.remaining() < RECORD_HEADER_SIZE + 1) {
            consumeBlock(true);
        }
    }

    private void getRecord(ByteBuffer buffer, RecordHeader header) throws IOException {
        Checksum computedChecksum = new CRC32();
        computedChecksum.update(currentBlock.array(), currentBlock.position(), header.getSize());

        if ((int) computedChecksum.getValue() != header.getChecksum()) {
            throw new RuntimeException("invalid checksum of record");
        }

        buffer.put(currentBlock.array(), currentBlock.position(), header.getSize());
        currentBlock.position(currentBlock.position() + header.getSize());
    }

    /**
     * @return
     * @throws IOException
     */
    public byte[] readEvent() throws IOException {
        if (consumeToStartOfEvent() == false) {
            return null;
        }
        RecordHeader header = RecordHeader.get(currentBlock);
        int cumReadSize = 0;
        int bufferSize = header.getTotalEventSize().orElseGet(header::getSize);
        ByteBuffer buffer = ByteBuffer.allocate(bufferSize);
        getRecord(buffer, header);
        cumReadSize += header.getSize();
        while (cumReadSize < bufferSize) {
            maybeRollToNextBlock();
            RecordHeader nextHeader = RecordHeader.get(currentBlock);
            getRecord(buffer, nextHeader);
            cumReadSize += nextHeader.getSize();
        }
        return buffer.array();
    }

    public void close() throws IOException {
        channel.close();
    }
}
