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

import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;

/**
 */
public class RecordIOReader {

    private final FileChannel channel;
    private final ByteBuffer currentBlock;
    private final Path path;
    private boolean endOfStream;

    public RecordIOReader(Path path) throws IOException {
        this.path = path;
        this.channel = FileChannel.open(path, StandardOpenOption.READ);
        this.currentBlock = ByteBuffer.allocate(BLOCK_SIZE);
        this.endOfStream = true;
    }

    private void seekNextBlock() throws IOException {
        seekNextBlock(false);
    }

    private void seekNextBlock(boolean fresh) throws IOException {
        long prev = channel.position();
        int keepPosition;
        if (fresh) {
            keepPosition = 0;
        } else if (endOfStream && currentBlock.hasRemaining()) {
            keepPosition = currentBlock.position();
        } else {
            keepPosition = 0;
        }
        currentBlock.position(0);
        if (channel.read(currentBlock) < BLOCK_SIZE) {
            endOfStream = true;
            channel.position(prev);
        } else {
            endOfStream = false;
        }
        currentBlock.rewind();
        currentBlock.position(keepPosition);
    }

    public void seekNextBlock(int bid) throws IOException {
        currentBlock.position(currentBlock.limit());
        channel.position(bid * BLOCK_SIZE);
        seekNextBlock(true);
    }

    public Path getPath() {
        return path;
    }

    public boolean isEndOfStream() {
        return endOfStream;
    }

    /**
     * TODO(talevy): split out seeking to first record and/or end of buffer vs. actually reading the record
     * @return
     * @throws IOException
     */
    public byte[] readRecord() throws IOException {
        if (endOfStream) {
            seekNextBlock();
        }
        if (!currentBlock.hasRemaining() || currentBlock.remaining() < RECORD_HEADER_SIZE + 1) {
            return null;
        }
        // read header
        RecordType type = RecordType.fromByte(currentBlock.get());

        final int totalSize;
        int size;
        int cumReadSize = 0;
        if (type == RecordType.START) {
            size = currentBlock.getInt();
            totalSize = currentBlock.getInt();
        } else if (type == RecordType.COMPLETE) {
            totalSize = currentBlock.getInt();
            size = totalSize;
        } else if (type == RecordType.MIDDLE) {
            seekNextBlock(true);
            return readRecord();
        } else if (type == RecordType.END){
            size = currentBlock.getInt();
            currentBlock.position(currentBlock.position() + size);
            return readRecord();
        } else {
            currentBlock.position(currentBlock.position() - 1);
            return null;
        }
        ByteBuffer buffer = ByteBuffer.allocate(totalSize);
        buffer.put(currentBlock.array(), currentBlock.position(), size);
        currentBlock.position(currentBlock.position() + size);
        cumReadSize += size;

        if (!currentBlock.hasRemaining()) {
            seekNextBlock();
        }

        while (cumReadSize < totalSize) {
            type = RecordType.fromByte(currentBlock.get());
            if (type == null) {
                break;
            }
            size = currentBlock.getInt();
            buffer.put(currentBlock.array(), currentBlock.position(), size);
            currentBlock.position(currentBlock.position() + size);
            cumReadSize += size;
            if (!currentBlock.hasRemaining() && type != RecordType.END) {
                seekNextBlock();
            }
        }
        return buffer.array();
    }

    public void close() throws IOException {
        channel.close();
    }
}
