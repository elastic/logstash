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

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.CRC32;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ackedqueue.SequencedList;

/**
 * Internal API, v2 mmap implementation of {@link PageIO}
 * */
public final class MmapPageIOV2 implements PageIO {

    public static final byte VERSION_TWO = (byte) 2;
    public static final int VERSION_SIZE = Byte.BYTES;
    public static final int CHECKSUM_SIZE = Integer.BYTES;
    public static final int LENGTH_SIZE = Integer.BYTES;
    public static final int SEQNUM_SIZE = Long.BYTES;
    public static final int MIN_CAPACITY = VERSION_SIZE + SEQNUM_SIZE + LENGTH_SIZE + 1 + CHECKSUM_SIZE; // header overhead plus elements overhead to hold a single 1 byte element
    public static final int HEADER_SIZE = 1;     // version byte
    public static final boolean VERIFY_CHECKSUM = true;

    private static final Logger LOGGER = LogManager.getLogger(MmapPageIOV2.class);

    /**
     * Cleaner function for forcing unmapping of backing {@link MmapPageIOV2#buffer}.
     */
    private static final ByteBufferCleaner BUFFER_CLEANER = new ByteBufferCleanerImpl();

    private final File file;

    private final CRC32 checkSummer;

    private final IntVector offsetMap;

    private int capacity; // page capacity is an int per the ByteBuffer class.
    private long minSeqNum; // TODO: to make minSeqNum final we have to pass in the minSeqNum in the constructor and not set it on first write
    private int elementCount;
    private int head; // head is the write position and is an int per ByteBuffer class position
    private byte version;

    private MappedByteBuffer buffer;

    public MmapPageIOV2(int pageNum, int capacity, Path dirPath) {
        this.minSeqNum = 0;
        this.elementCount = 0;
        this.version = 0;
        this.head = 0;
        this.capacity = capacity;
        this.offsetMap = new IntVector();
        this.checkSummer = new CRC32();
        this.file = dirPath.resolve("page." + pageNum).toFile();
    }

    @Override
    public void open(long minSeqNum, int elementCount) throws IOException {
        mapFile();
        buffer.position(0);
        this.version = buffer.get();
        validateVersion(this.version);
        this.head = 1;

        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;

        if (this.elementCount > 0) {
            // verify first seqNum to be same as expected minSeqNum
            long seqNum = buffer.getLong();
            if (seqNum != this.minSeqNum) {
                throw new IOException(String.format("first seqNum=%d is different than minSeqNum=%d", seqNum, this.minSeqNum));
            }

            // reset back position to first seqNum
            buffer.position(this.head);

            for (int i = 0; i < this.elementCount; i++) {
                // verify that seqNum must be of strict + 1 increasing order
                readNextElement(this.minSeqNum + i, !VERIFY_CHECKSUM);
            }
        }
    }

    @Override
    public SequencedList<byte[]> read(long seqNum, int limit) throws IOException {
        assert seqNum >= this.minSeqNum :
            String.format("seqNum=%d < minSeqNum=%d", seqNum, this.minSeqNum);
        assert seqNum <= maxSeqNum() :
            String.format("seqNum=%d is > maxSeqNum=%d", seqNum, maxSeqNum());

        List<byte[]> elements = new ArrayList<>();
        final LongVector seqNums = new LongVector(limit);

        int offset = this.offsetMap.get((int) (seqNum - this.minSeqNum));

        buffer.position(offset);

        for (int i = 0; i < limit; i++) {
            long readSeqNum = buffer.getLong();

            assert readSeqNum == (seqNum + i) :
                String.format("unmatched seqNum=%d to readSeqNum=%d", seqNum + i, readSeqNum);

            int readLength = buffer.getInt();
            byte[] readBytes = new byte[readLength];
            buffer.get(readBytes);
            int checksum = buffer.getInt();
            int computedChecksum = checksum(readBytes);
            if (computedChecksum != checksum) {
                throw new IOException(String.format("computed checksum=%d != checksum for file=%d", computedChecksum, checksum));
            }

            elements.add(readBytes);
            seqNums.add(readSeqNum);

            if (seqNum + i >= maxSeqNum()) {
                break;
            }
        }

        return new SequencedList<>(elements, seqNums);
    }

    // recover will overwrite/update/set this object minSeqNum, capacity and elementCount attributes
    // to reflect what it recovered from the page
    @Override
    public void recover() throws IOException {
        mapFile();
        buffer.position(0);
        this.version = buffer.get();
        validateVersion(this.version);
        this.head = 1;

        // force minSeqNum to actual first element seqNum
        this.minSeqNum = buffer.getLong();
        // reset back position to first seqNum
        buffer.position(this.head);

        // reset elementCount to 0 and increment to octal number of valid elements found
        this.elementCount = 0;

        for (int i = 0; ; i++) {
            try {
                // verify that seqNum must be of strict + 1 increasing order
                readNextElement(this.minSeqNum + i, VERIFY_CHECKSUM);
                this.elementCount += 1;
            } catch (MmapPageIOV2.PageIOInvalidElementException e) {
                // simply stop at first invalid element
                LOGGER.debug("PageIO recovery for '{}' element index:{}, readNextElement exception: {}", file, i, e.getMessage());
                break;
            }
        }

        // if we were not able to read any element just reset minSeqNum to zero
        if (this.elementCount <= 0) {
            this.minSeqNum = 0;
        }
    }

    @Override
    public void create() throws IOException {
        try (RandomAccessFile raf = new RandomAccessFile(this.file, "rw")) {
            this.buffer = raf.getChannel().map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
        }
        buffer.position(0);
        buffer.put(VERSION_TWO);
        buffer.force();
        this.head = 1;
        this.minSeqNum = 0L;
        this.elementCount = 0;
    }

    @Override
    public void deactivate() {
        close(); // close can be called multiple times
    }

    @Override
    public void activate() throws IOException {
        if (this.buffer == null) {
            try (RandomAccessFile raf = new RandomAccessFile(this.file, "rw")) {
                this.buffer = raf.getChannel().map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
            }
            this.buffer.load();
        }
        // TODO: do we need to check is the channel is still open? not sure how it could be closed
    }

    @Override
    public void ensurePersisted() {
        this.buffer.force();
    }

    @Override
    public void purge() throws IOException {
        close();
        this.head = 0;
        LOGGER.debug("PageIO deleting '{}'", this.file);
        Files.delete(this.file.toPath());
    }

    @Override
    public void write(byte[] bytes, long seqNum) {
        write(bytes, seqNum, bytes.length, checksum(bytes));
    }

    @Override
    public void close() {
        if (this.buffer != null) {
            this.buffer.force();
            BUFFER_CLEANER.clean(buffer);

        }
        this.buffer = null;
    }

    @Override
    public int getCapacity() {
        return this.capacity;
    }

    @Override
    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    @Override
    public int getElementCount() {
        return this.elementCount;
    }

    @Override
    public boolean hasSpace(int bytes) {
        int bytesLeft = this.capacity - this.head;
        return persistedByteCount(bytes) <= bytesLeft;
    }

    @Override
    public int persistedByteCount(int byteCount) {
        return SEQNUM_SIZE + LENGTH_SIZE + byteCount + CHECKSUM_SIZE;
    }

    @Override
    public int getHead() {
        return this.head;
    }

    @Override
    public boolean isCorruptedPage() throws IOException {
        try (RandomAccessFile raf = new RandomAccessFile(this.file, "rw")) {
            return raf.length() < MIN_CAPACITY;
        }
    }

    private int checksum(byte[] bytes) {
        checkSummer.reset();
        checkSummer.update(bytes, 0, bytes.length);
        return (int) checkSummer.getValue();
    }

    private long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }

    // memory map data file to this.buffer and read initial version byte
    private void mapFile() throws IOException {
        try (RandomAccessFile raf = new RandomAccessFile(this.file, "rw")) {

            if (raf.length() > Integer.MAX_VALUE) {
                throw new IOException("Page file too large " + this.file);
            }
            int pageFileCapacity = (int) raf.length();

            // update capacity to actual raf length. this can happen if a page size was changed on a non empty queue directory for example.
            this.capacity = pageFileCapacity;

            if (this.capacity < MIN_CAPACITY) {
                throw new IOException("Page file size is too small to hold elements. " +
                        "This is potentially a queue corruption problem. Run `pqcheck` and `pqrepair` to repair the queue.");
            }
            this.buffer = raf.getChannel().map(FileChannel.MapMode.READ_WRITE, 0, this.capacity);
        }
        this.buffer.load();
    }

    // read and validate next element at page head
    // @param verifyChecksum if true the actual element data will be read + checksumed and compared to written checksum
    private void readNextElement(long expectedSeqNum, boolean verifyChecksum) throws MmapPageIOV2.PageIOInvalidElementException {
        // if there is no room for the seqNum and length bytes stop here
        // TODO: I know this isn't a great exception message but at the time of writing I couldn't come up with anything better :P
        if (this.head + SEQNUM_SIZE + LENGTH_SIZE > capacity) {
            throw new MmapPageIOV2.PageIOInvalidElementException(
                "cannot read seqNum and length bytes past buffer capacity");
        }

        int elementOffset = this.head;
        int newHead = this.head;

        long seqNum = buffer.getLong();
        newHead += SEQNUM_SIZE;

        if (seqNum != expectedSeqNum) {
            throw new MmapPageIOV2.PageIOInvalidElementException(
                String.format("Element seqNum %d is expected to be %d", seqNum, expectedSeqNum));
        }

        int length = buffer.getInt();
        newHead += LENGTH_SIZE;

        // length must be > 0
        if (length <= 0) {
            throw new MmapPageIOV2.PageIOInvalidElementException("Element invalid length");
        }

        // if there is no room for the proposed data length and checksum just stop here
        if (newHead + length + CHECKSUM_SIZE > capacity) {
            throw new MmapPageIOV2.PageIOInvalidElementException(
                "cannot read element payload and checksum past buffer capacity");
        }

        if (verifyChecksum) {
            // read data and compute checksum;
            this.checkSummer.reset();
            final int prevLimit = buffer.limit();
            buffer.limit(buffer.position() + length);
            this.checkSummer.update(buffer);
            buffer.limit(prevLimit);
            int checksum = buffer.getInt();
            int computedChecksum = (int) this.checkSummer.getValue();
            if (computedChecksum != checksum) {
                throw new MmapPageIOV2.PageIOInvalidElementException("Element invalid checksum");
            }
        }

        // at this point we recovered a valid element
        this.offsetMap.add(elementOffset);
        this.head = newHead + length + CHECKSUM_SIZE;

        buffer.position(this.head);
    }

    private int write(byte[] bytes, long seqNum, int length, int checksum) {
        // since writes always happen at head, we can just append head to the offsetMap
        assert this.offsetMap.size() == this.elementCount :
            String.format("offsetMap size=%d != elementCount=%d", this.offsetMap.size(), this.elementCount);

        int initialHead = this.head;
        buffer.position(this.head);
        buffer.putLong(seqNum);
        buffer.putInt(length);
        buffer.put(bytes);
        buffer.putInt(checksum);
        this.head += persistedByteCount(bytes.length);

        assert this.head == buffer.position() :
            String.format("head=%d != buffer position=%d", this.head, buffer.position());

        if (this.elementCount <= 0) {
            this.minSeqNum = seqNum;
        }
        this.offsetMap.add(initialHead);
        this.elementCount++;

        return initialHead;
    }

    // we don't have different versions yet so simply check if the version is VERSION_ONE for basic integrity check
    // and if an unexpected version byte is read throw PageIOInvalidVersionException
    private static void validateVersion(byte version)
        throws MmapPageIOV2.PageIOInvalidVersionException {
        if (version != VERSION_TWO) {
            throw new MmapPageIOV2.PageIOInvalidVersionException(String
                .format("Expected page version=%d but found version=%d", VERSION_TWO, version));
        }
    }

    @Override
    public String toString() {
        return "MmapPageIOV2{" +
                "file=" + file +
                ", capacity=" + capacity +
                ", minSeqNum=" + minSeqNum +
                ", elementCount=" + elementCount +
                ", head=" + head +
                '}';
    }

    /**
     * Invalid Page structure exception
     * */
    public static final class PageIOInvalidElementException extends IOException {

        private static final long serialVersionUID = 1L;

        public PageIOInvalidElementException(String message) {
            super(message);
        }
    }

    /**
     * Invalid page version exception.
     * */
    public static final class PageIOInvalidVersionException extends IOException {

        private static final long serialVersionUID = 1L;

        public PageIOInvalidVersionException(String message) {
            super(message);
        }
    }
}
