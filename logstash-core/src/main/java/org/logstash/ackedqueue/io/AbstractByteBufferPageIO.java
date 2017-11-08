package org.logstash.ackedqueue.io;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.CRC32;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.ackedqueue.SequencedList;

public abstract class AbstractByteBufferPageIO implements PageIO {

    public static class PageIOInvalidElementException extends IOException {
        public PageIOInvalidElementException(String message) { super(message); }
    }

    public static class PageIOInvalidVersionException extends IOException {
        public PageIOInvalidVersionException(String message) { super(message); }
    }

    public static final byte VERSION_ONE = 1;
    public static final int VERSION_SIZE = Byte.BYTES;
    public static final int CHECKSUM_SIZE = Integer.BYTES;
    public static final int LENGTH_SIZE = Integer.BYTES;
    public static final int SEQNUM_SIZE = Long.BYTES;
    public static final int HEADER_SIZE = 1;     // version byte
    public static final int MIN_CAPACITY = VERSION_SIZE + SEQNUM_SIZE + LENGTH_SIZE + 1 + CHECKSUM_SIZE; // header overhead plus elements overhead to hold a single 1 byte element

    // Size of: Header + Sequence Number + Length + Checksum
    public static final int WRAPPER_SIZE = HEADER_SIZE + SEQNUM_SIZE + LENGTH_SIZE + CHECKSUM_SIZE;

    public static final boolean VERIFY_CHECKSUM = true;

    private static final Logger logger = LogManager.getLogger(AbstractByteBufferPageIO.class);

    protected int capacity; // page capacity is an int per the ByteBuffer class.
    protected final int pageNum;
    protected long minSeqNum; // TODO: to make minSeqNum final we have to pass in the minSeqNum in the constructor and not set it on first write
    protected int elementCount;
    protected int head; // head is the write position and is an int per ByteBuffer class position
    protected byte version;
    private CRC32 checkSummer;
    private final IntVector offsetMap;

    public AbstractByteBufferPageIO(int pageNum, int capacity) {
        this.minSeqNum = 0;
        this.elementCount = 0;
        this.version = 0;
        this.head = 0;
        this.pageNum = pageNum;
        this.capacity = capacity;
        this.offsetMap = new IntVector();
        this.checkSummer = new CRC32();
    }

    // @return the concrete class buffer
    protected abstract ByteBuffer getBuffer();

    @Override
    public void open(long minSeqNum, int elementCount) throws IOException {
        getBuffer().position(0);
        this.version = getBuffer().get();
        validateVersion(this.version);
        this.head = 1;

        this.minSeqNum = minSeqNum;
        this.elementCount = elementCount;

        if (this.elementCount > 0) {
            // verify first seqNum to be same as expected minSeqNum
            long seqNum = getBuffer().getLong();
            if (seqNum != this.minSeqNum) { throw new IOException(String.format("first seqNum=%d is different than minSeqNum=%d", seqNum, this.minSeqNum)); }

            // reset back position to first seqNum
            getBuffer().position(this.head);

            for (int i = 0; i < this.elementCount; i++) {
                // verify that seqNum must be of strict + 1 increasing order
                readNextElement(this.minSeqNum + i, !VERIFY_CHECKSUM);
            }
        }
    }

    // recover will overwrite/update/set this object minSeqNum, capacity and elementCount attributes
    // to reflect what it recovered from the page
    @Override
    public void recover() throws IOException {
        getBuffer().position(0);
        this.version = getBuffer().get();
        validateVersion(this.version);
        this.head = 1;

        // force minSeqNum to actual first element seqNum
        this.minSeqNum = getBuffer().getLong();
        // reset back position to first seqNum
        getBuffer().position(this.head);

        // reset elementCount to 0 and increment to octal number of valid elements found
        this.elementCount = 0;

        for (int i = 0; ; i++) {
            try {
                // verify that seqNum must be of strict + 1 increasing order
                readNextElement(this.minSeqNum + i, VERIFY_CHECKSUM);
                this.elementCount += 1;
            } catch (PageIOInvalidElementException e) {
                // simply stop at first invalid element
                logger.debug("PageIO recovery element index:{}, readNextElement exception: {}", i, e.getMessage());
                break;
            }
        }

        // if we were not able to read any element just reset minSeqNum to zero
        if (this.elementCount <= 0) {
            this.minSeqNum = 0;
        }
    }

    // we don't have different versions yet so simply check if the version is VERSION_ONE for basic integrity check
    // and if an unexpected version byte is read throw PageIOInvalidVersionException
    private static void validateVersion(byte version) throws PageIOInvalidVersionException {
        if (version != VERSION_ONE) {
            throw new PageIOInvalidVersionException(String
                .format("Expected page version=%d but found version=%d", VERSION_ONE, version));
        }
    }

    // read and validate next element at page head
    // @param verifyChecksum if true the actual element data will be read + checksumed and compared to written checksum
    private void readNextElement(long expectedSeqNum, boolean verifyChecksum) throws PageIOInvalidElementException {
        // if there is no room for the seqNum and length bytes stop here
        // TODO: I know this isn't a great exception message but at the time of writing I couldn't come up with anything better :P
        if (this.head + SEQNUM_SIZE + LENGTH_SIZE > capacity) { throw new PageIOInvalidElementException(
            "cannot read seqNum and length bytes past buffer capacity"); }

        int elementOffset = this.head;
        int newHead = this.head;
        ByteBuffer buffer = getBuffer();

        long seqNum = buffer.getLong();
        newHead += SEQNUM_SIZE;

        if (seqNum != expectedSeqNum) { throw new PageIOInvalidElementException(
            String.format("Element seqNum %d is expected to be %d", seqNum, expectedSeqNum)); }

        int length = buffer.getInt();
        newHead += LENGTH_SIZE;

        // length must be > 0
        if (length <= 0) { throw new PageIOInvalidElementException("Element invalid length"); }

        // if there is no room for the proposed data length and checksum just stop here
        if (newHead + length + CHECKSUM_SIZE > capacity) { throw new PageIOInvalidElementException(
            "cannot read element payload and checksum past buffer capacity"); }

        if (verifyChecksum) {
            // read data and compute checksum;
            this.checkSummer.reset();
            final int prevLimit = buffer.limit();
            buffer.limit(buffer.position() + length);
            this.checkSummer.update(buffer);
            buffer.limit(prevLimit);
            int checksum = buffer.getInt();
            int computedChecksum = (int) this.checkSummer.getValue();
            if (computedChecksum != checksum) { throw new PageIOInvalidElementException(
                "Element invalid checksum"); }
        }

        // at this point we recovered a valid element
        this.offsetMap.add(elementOffset);
        this.head = newHead + length + CHECKSUM_SIZE;

        buffer.position(this.head);
    }

    @Override
    public void create() throws IOException {
        getBuffer().position(0);
        getBuffer().put(VERSION_ONE);
        this.head = 1;
        this.minSeqNum = 0L;
        this.elementCount = 0;
    }

    @Override
    public void write(byte[] bytes, long seqNum) {
        write(bytes, seqNum, bytes.length, checksum(bytes));
    }

    protected int write(byte[] bytes, long seqNum, int length, int checksum) {
        // since writes always happen at head, we can just append head to the offsetMap
        assert this.offsetMap.size() == this.elementCount :
                String.format("offsetMap size=%d != elementCount=%d", this.offsetMap.size(), this.elementCount);

        int initialHead = this.head;
        ByteBuffer buffer = getBuffer();

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

    @Override
    public SequencedList<byte[]> read(long seqNum, int limit) throws IOException {
        assert seqNum >= this.minSeqNum :
                String.format("seqNum=%d < minSeqNum=%d", seqNum, this.minSeqNum);
        assert seqNum <= maxSeqNum() :
                String.format("seqNum=%d is > maxSeqNum=%d", seqNum, maxSeqNum());

        List<byte[]> elements = new ArrayList<>();
        final LongVector seqNums = new LongVector(limit);

        int offset = this.offsetMap.get((int)(seqNum - this.minSeqNum));

        ByteBuffer buffer = getBuffer();
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

    @Override
    public int getCapacity() { return this.capacity; }

    @Override
    public long getMinSeqNum() { return this.minSeqNum; }

    @Override
    public int getElementCount() { return this.elementCount; }

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

    protected int checksum(byte[] bytes) {
        checkSummer.reset();
        checkSummer.update(bytes, 0, bytes.length);
        return (int) checkSummer.getValue();
    }

    private long maxSeqNum() {
        return this.minSeqNum + this.elementCount - 1;
    }
}
