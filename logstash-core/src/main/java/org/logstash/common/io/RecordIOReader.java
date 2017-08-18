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
import java.nio.channels.ClosedByInterruptException;
import java.nio.channels.FileChannel;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Arrays;
import java.util.Comparator;
import java.util.function.Function;
import java.util.zip.CRC32;
import java.util.zip.Checksum;

import static org.logstash.common.io.RecordIOWriter.BLOCK_SIZE;
import static org.logstash.common.io.RecordIOWriter.RECORD_HEADER_SIZE;
import static org.logstash.common.io.RecordIOWriter.VERSION;
import static org.logstash.common.io.RecordIOWriter.VERSION_SIZE;

/**
 */
public final class RecordIOReader implements Closeable {

    private final FileChannel channel;
    private ByteBuffer currentBlock;
    private int currentBlockSizeReadFromChannel;
    private final Path path;
    private long channelPosition;
    private static final int UNSET = -1;

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
        this.channelPosition = this.channel.position();
    }

    public Path getPath() {
        return path;
    }

    public void seekToBlock(int bid) throws IOException {
        seekToOffset(bid * BLOCK_SIZE + VERSION_SIZE);
    }

    public void seekToOffset(long channelOffset) throws IOException {
        currentBlock.rewind();
        currentBlockSizeReadFromChannel = 0;
        channel.position(channelOffset);
        channelPosition = channel.position();
    }

    public <T> byte[] seekToNextEventPosition(T target, Function<byte[], T> keyExtractor, Comparator<T> keyComparator) throws IOException {
        int matchingBlock = UNSET;
        int lowBlock = 0;
        int highBlock = (int) (channel.size() - VERSION_SIZE) / BLOCK_SIZE;

        while (lowBlock < highBlock) {
            int middle = (int) Math.ceil((highBlock + lowBlock) / 2.0);
            seekToBlock(middle);
            byte[] readEvent = readEvent();
            // If the event is null, scan from the low block upwards
            if (readEvent == null){
                matchingBlock = lowBlock;
                break;
            }
            T found = keyExtractor.apply(readEvent);
            int compare = keyComparator.compare(found, target);
            if (compare > 0) {
                highBlock = middle - 1;
            } else if (compare < 0) {
                lowBlock = middle;
            } else {
                matchingBlock = middle;
                break;
            }
        }
        if (matchingBlock == UNSET) {
            matchingBlock = lowBlock;
        }

        // now sequential scan to event
        seekToBlock(matchingBlock);
        int compare = -1;
        byte[] event = null;
        BufferState restorePoint = null;
        while (compare < 0) {
            // Save the buffer state when reading the next event, to restore to if a matching event is found.
            restorePoint = saveBufferState();
            event = readEvent();
            if (event == null) {
                return null;
            }
            compare = keyComparator.compare(keyExtractor.apply(event), target);
        }
        if (restorePoint != null) {
            restoreFrom(restorePoint);
        }
        return event;
    }

    public long getChannelPosition() {
        return channelPosition;
    }

    void consumeBlock(boolean rewind) throws IOException {
        if (rewind) {
            currentBlockSizeReadFromChannel = 0;
            currentBlock.rewind();
        } else if (currentBlockSizeReadFromChannel == BLOCK_SIZE) {
            // already read enough, no need to read more
            return;
        }
        int processedPosition = currentBlock.position();
        try {
            // Move to last written to position
            currentBlock.position(currentBlockSizeReadFromChannel);
            channel.read(currentBlock);
            currentBlockSizeReadFromChannel = currentBlock.position();
        } finally {
            currentBlock.position(processedPosition);
        }
    }

    /**
     * basically, is last block
     * @return true if this is the end of the stream
     */
    public boolean isEndOfStream() {
        return currentBlockSizeReadFromChannel < BLOCK_SIZE;
    }

    /**
     *
     */
     int seekToStartOfEventInBlock() {
         // Already consumed all the bytes in this block.
         if (currentBlock.position() >= currentBlockSizeReadFromChannel){
             return -1;
         }
         while (true) {
             RecordType type = RecordType.fromByte(currentBlock.array()[currentBlock.arrayOffset() + currentBlock.position()]);
             if (RecordType.COMPLETE.equals(type) || RecordType.START.equals(type)) {
                 return currentBlock.position();
             } else if (RecordType.END.equals(type)) {
                 RecordHeader header = RecordHeader.get(currentBlock);
                 currentBlock.position(currentBlock.position() + header.getSize());
                 // If this is the end of stream, then cannot seek to start of block
                 if (this.isEndOfStream()){
                     return -1;
                 }
             } else {
                 return -1;
             }
         }
     }

    /**
     *
     * @return true if ready to read event, false otherwise
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

    private void getRecord(ByteBuffer buffer, RecordHeader header) {
        Checksum computedChecksum = new CRC32();
        computedChecksum.update(currentBlock.array(), currentBlock.position(), header.getSize());

        if ((int) computedChecksum.getValue() != header.getChecksum()) {
            throw new RuntimeException("invalid checksum of record");
        }

        buffer.put(currentBlock.array(), currentBlock.position(), header.getSize());
        currentBlock.position(currentBlock.position() + header.getSize());
    }

    public byte[] readEvent() throws IOException {
        try {
            if (channel.isOpen() == false || consumeToStartOfEvent() == false) {
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
        } catch (ClosedByInterruptException e) {
            return null;
        } finally {
            if (channel.isOpen()) {
                channelPosition = channel.position();
            }
        }
    }

    @Override
    public void close() throws IOException {
        channel.close();
    }


    private BufferState saveBufferState() throws IOException {
        return new BufferState.Builder().channelPosition(channel.position())
                                        .blockContents(Arrays.copyOf(this.currentBlock.array(), this.currentBlock.array().length))
                                        .currentBlockPosition(currentBlock.position())
                                        .currentBlockSizeReadFromChannel(currentBlockSizeReadFromChannel)
                                        .build();
    }

    private void restoreFrom(BufferState bufferState) throws IOException {
        this.currentBlock = ByteBuffer.wrap(bufferState.blockContents);
        this.currentBlock.position(bufferState.currentBlockPosition);
        this.channel.position(bufferState.channelPosition);
        this.channelPosition = channel.position();
        this.currentBlockSizeReadFromChannel = bufferState.currentBlockSizeReadFromChannel;
    }

    final static class BufferState {
        private int currentBlockPosition;
        private int currentBlockSizeReadFromChannel;
        private long channelPosition;
        private byte[] blockContents;

        BufferState(Builder builder){
            this.currentBlockPosition = builder.currentBlockPosition;
            this.currentBlockSizeReadFromChannel = builder.currentBlockSizeReadFromChannel;
            this.channelPosition = builder.channelPosition;
            this.blockContents = builder.blockContents;
        }

        public String toString() {
            return String.format("CurrentBlockPosition:%d, currentBlockSizeReadFromChannel: %d, channelPosition: %d",
                    currentBlockPosition, currentBlockSizeReadFromChannel, channelPosition);
        }

        final static class Builder{
            private int currentBlockPosition;
            private int currentBlockSizeReadFromChannel;
            private long channelPosition;
            private byte[] blockContents;

            Builder currentBlockPosition(final int currentBlockPosition){
                this.currentBlockPosition = currentBlockPosition;
                return this;
            }

            Builder currentBlockSizeReadFromChannel(final int currentBlockSizeReadFromChannel){
                this.currentBlockSizeReadFromChannel = currentBlockSizeReadFromChannel;
                return this;
            }

            Builder channelPosition(final long channelPosition){
                this.channelPosition = channelPosition;
                return this;
            }

            Builder blockContents(final byte[] blockContents){
                this.blockContents = blockContents;
                return this;
            }

            BufferState build(){
                return new BufferState(this);
            }
        }
    }
}
