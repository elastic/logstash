package org.logstash.common.io;

import org.logstash.ackedqueue.Queueable;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;

// TODO: currently assuming continuous seqNum is the byte buffer where we can deduct the maxSeqNum from the min + count.
// TODO: we could change this and support non-continuous seqNums but I am not sure we should.
// TODO: checksum is not currently computed.

public class ByteBufferPageIO implements PageIO {
    public static final byte VERSION = 1;
    public static final int CHECKSUM_SIZE = Integer.BYTES;
    public static final int LENGTH_SIZE = Integer.BYTES;
    public static final int SEQNUM_SIZE = Long.BYTES;
    public static final int MIN_RECORD_SIZE = SEQNUM_SIZE + CHECKSUM_SIZE;
    public static final int HEADER_SIZE = 1;     // version byte
    static final List<ReadElementValue> EMPTY_READ = new ArrayList<>(0);

    private final int capacity;
    private final List<Integer> offsetMap; // has to be extendable
    private final ByteBuffer buffer;
    private long minSeqNum; // TODO: to make minSeqNum final we have to pass in the minSeqNum in the constructor and not set it on first write
    private int elementCount;
    private int head;
    private byte version;

    public ByteBufferPageIO(int pageNum, int capacity, String path) throws IOException {
        this(capacity, new byte[0]);
    }

    public ByteBufferPageIO(int capacity) throws IOException {
        this(capacity, new byte[0]);
    }

    public ByteBufferPageIO(int capacity, byte[] initialBytes) throws IOException {
        this.capacity = capacity;
        if (initialBytes.length > capacity) {
            throw new IOException("initial bytes greater than capacity");
        }

        this.buffer = ByteBuffer.allocate(capacity);
        this.buffer.put(initialBytes);

        this.offsetMap = new ArrayList<>();
    }

    public void open(long minSeqNum, int elementCount) throws IOException {
        // TODO: do we need to do something there?
        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;

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

    public void create() throws IOException {
        this.buffer.position(0);
        this.buffer.put(VERSION);
        this.head = 1;
        this.minSeqNum = 0;
        this.elementCount = 0;
    }

    public int getCapacity() {
        return this.capacity;
    }

    public long getMinSeqNum() {
        return this.minSeqNum;
    }

    public boolean hasSpace(int bytes) {
        int bytesLeft = this.capacity - this.head;
        return persistedByteCount(bytes) <= bytesLeft;
    }

    public void write(byte[] bytes, Queueable element) throws IOException {
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

    public List<ReadElementValue> read(long seqNum, int limit) throws IOException {
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

    public void deactivate() {
        // nothing to do
    }

    public void activate() {
        // nothing to do
    }

    public void ensurePersisted() {
        // nothing to do
    }

    @Override
    public void purge() throws IOException {
        // do nothing
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

    public byte[] dump() {
        return this.buffer.array();
    }
}
