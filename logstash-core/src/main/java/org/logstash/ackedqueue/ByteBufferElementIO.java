package org.logstash.ackedqueue;

import org.logstash.common.io.ReadElementValue;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

// TODO: currently assuming continuous seqNum is the byte buffer where we can deduct the maxSeqNum from the min + count.
// TODO: we could change this and support non-continuous seqNums but I am not sure we should.
// TODO: checksum is not currently computed.

public class ByteBufferElementIO implements ElementIO {
    static final int CHECKSUM_SIZE = Integer.BYTES;
    static final int LENGTH_SIZE = Integer.BYTES;
    static final int SEQNUM_SIZE = Long.BYTES;
    static final int MIN_RECORD_SIZE = SEQNUM_SIZE + CHECKSUM_SIZE;
    static final int HEADER_SIZE = 1;     // version byte
    static final List<ReadElementValue> EMPTY_READ = new ArrayList<>(0);

    private final int capacity;
    private final List<Integer> offsetMap; // has to be extendable
    private final ByteBuffer buffer;
    private long minSeqNum; // TODO: to make minSeqNum final we have to pass in the minSeqNum in the constructor and not set it on first write
    private int elementCount;
    private int head;
    private final byte version;

    public ByteBufferElementIO() {
        // dummy noarg constructor
        this.capacity = 0;
        this.offsetMap = null;
        this.buffer = null;
        this.version = 0;
    }

    public ElementIO open(int capacity, String path, long minSeqNum, int elementCount) throws IOException {
        return new ByteBufferElementIO(capacity, new byte[0], minSeqNum, elementCount);
    }

    public ElementIO create(int capacity, String path) throws IOException {
        return new ByteBufferElementIO(capacity);
    }

    public int getCapacity() {
        return this.capacity;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public ByteBufferElementIO(int capacity) throws IOException {
        this(capacity, new byte[0], 1L, 0);
    }


    public ByteBufferElementIO(int capacity, byte[] initialBytes, long minSeqNum, int elementCount) throws IOException {
        this.capacity = capacity;
        if (initialBytes.length > capacity) {
            throw new IOException("initial bytes greater than capacity");
        }

        this.buffer = ByteBuffer.allocate(capacity);
        this.buffer.put(initialBytes);
        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;
        this.offsetMap = new ArrayList<>();

        this.buffer.position(0);
        this.version = this.buffer.get();
        this.head = 1;

        if (this.elementCount > 0) {

            // TODO: refactor the read logic below to DRY with the read() method.

            // set head by skipping over all elements
            for (int i = 0; i < this.elementCount; i++) {
                if (this.head + SEQNUM_SIZE + LENGTH_SIZE > capacity) {
                    throw new IOException(String.format("cannot read seqNum and length bytes past buffer capacity"));
                }

                long seqNum = this.buffer.getLong();

                if (i == 0 && seqNum != this.minSeqNum) {
                    throw new IOException(String.format("first seqNum=%d is different than minSeqNum=%d", seqNum, this.minSeqNum));
                }

                this.offsetMap.add(head);
                this.head += SEQNUM_SIZE;


                int length = this.buffer.getInt();
                this.head += LENGTH_SIZE;

                if (this.head + length + CHECKSUM_SIZE > capacity) {
                    throw new IOException(String.format("cannot read element payload and checksum past buffer capacity"));
                }

                // skip over data
                this.head += length;
                this.head += CHECKSUM_SIZE;

                this.buffer.position(head);
            }
        }
    }

    public boolean hasSpace(int bytes) {
        int bytesLeft = this.capacity - this.head;
        return persistedByteCount(bytes) <= bytesLeft;
    }

    public void write(byte[] bytes, Queueable element) {
        // since writes always happen at head, we can just append head to the offsetMap
        assert this.offsetMap.size() == this.elementCount :
                String.format("offsetMap size=%d != elementCount=%d", this.offsetMap.size(), this.elementCount);

        int initialHead = this.head;

        this.buffer.position(this.head);
        this.buffer.putLong(element.getSeqNum());
        this.buffer.putInt(bytes.length);
        this.buffer.put(bytes);
        this.buffer.putInt(checksum(bytes));
        this.head += persistedByteCount(bytes.length);
        assert this.head == this.buffer.position() :
                String.format("head=%d != buffer position=%d", this.head, this.buffer.position());

        if (this.elementCount <= 0) {
            this.minSeqNum = element.getSeqNum();
        }
        this.offsetMap.add(initialHead);
        this.elementCount++;
    }

    public List<ReadElementValue> read(long seqNum, int limit) {
//        return new ArrayList<>();
        assert seqNum >= this.minSeqNum :
                String.format("seqNum=%d < minSeqNum=%d", seqNum, this.minSeqNum);
        assert seqNum <= maxSeqNum() :
                String.format("seqNum=%d is > maxSeqNum=%d", seqNum, maxSeqNum());

        List<ReadElementValue> result = new ArrayList<>();
        int offset = this.offsetMap.get((int)(seqNum - this.minSeqNum));

        this.buffer.position(offset);

        for (int i = 0; i < limit; i++) {
            long readSeqNum = this.buffer.getLong();

            assert readSeqNum == (seqNum + i) :
                    String.format("unmatched seqNum=%d to readSeqNum=%d", seqNum + i, readSeqNum);

            int readLength = this.buffer.getInt();
            byte[] readBytes = new byte[readLength];
            this.buffer.get(readBytes);
            int checksum = this.buffer.getInt();

            result.add(new ReadElementValue(readSeqNum, readBytes));

            if (seqNum + i >= maxSeqNum()) {
                break;
            }
        }

        assert result.get(0).getSeqNum() == seqNum :
                String.format("seqNum=%d != first result seqNum=%d");

        return result;
    }

    private int checksum(byte[] bytes) {
        return 0;
    }

    // made public only for tests
    public static int persistedByteCount(int byteCount) {
        return SEQNUM_SIZE + LENGTH_SIZE + byteCount + CHECKSUM_SIZE;
    }

    private long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }


    // below public methods only used by tests

    public int getWritePosition() {
        return this.head;
    }

    public int getElementCount() {
        return this.elementCount;
    }

    public long getStartSeqNum() {
        return this.minSeqNum;
    }

    public byte[] dump() {
        return this.buffer.array();
    }
}
