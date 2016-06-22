package org.logstash.ackedqueue;

import org.roaringbitmap.RoaringBitmap;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

public class MemoryPage implements Page {
    private final static List<Element> EMPTY_RESULT = new ArrayList<>(0);
    private final static int EMPTY_PAGE_HEAD = 0;

    private ByteBuffer data;
    private int capacity; // this page bytes capacity
    private int head;     // this page head offset
    private long index;    // this page index number

    private RoaringBitmap unused;
    private RoaringBitmap unacked;

    // @param capacity page byte size
    public MemoryPage(int capacity) {
        this(capacity, 0);
    }

    // @param capacity page byte size
    // @param index the page index number
    public MemoryPage(int capacity, long index) {
        this(capacity, index, ByteBuffer.allocate(capacity), EMPTY_PAGE_HEAD, new RoaringBitmap());
    }

    // @param capacity page byte size
    // @param index the page index number
    // @param data initial data for this page
    // @param head the page head offset, @see MemoryPage.findHead() if it needs to be resolved
    // @param unacked initial unacked state bitmap for this page
    public MemoryPage(int capacity, long index, ByteBuffer data, int head, RoaringBitmap unacked) {
        this.data = data;
        this.index = index;
        this.capacity = capacity;
        this.unused = unacked;
        this.unacked = new RoaringBitmap(unacked.toMutableRoaringBitmap());
        this.head = head;
    }

    // @return then new head position or 0 if not enough space left for data
    @Override
    public int write(byte[] data) {
        if (! writable(data.length)) {
            return 0;
        }

        this.data.position(this.head);

        // this write sequence total bytes must equate totalBytes(data.length)
        this.data.putInt(data.length);
        this.data.put(data);
        this.data.putInt(0);

        // set bitmaps
        this.unused.add(this.head);
        this.unacked.add(this.head);

        this.head += totalBytes(data.length);

        return this.head;
   }

    @Override
    public boolean writable(int bytes) {
        return (availableBytes() >= totalBytes(bytes));
    }

    @Override
    public List<Element> read(int n) {
        RoaringBitmap readable = readable();

        // empty result optimization
        if (readable.getCardinality() <= 0) {
            return EMPTY_RESULT;
        }

        List<Element> result = new ArrayList<>();

        Iterator i = new BatchedIterator(readable.iterator(), n);
        while (i.hasNext()) {
            int offset = (int) i.next();

            this.data.position(offset);

            int dataSize = this.data.getInt();
            assert dataSize > 0;

            byte[] payload = new byte[dataSize];;
            this.data.get(payload);

            // TODO: how/where should we track page index?
            result.add(new Element(payload, 0, offset));

            // set this item as in-use (unset unused bit)
            unused.remove(offset);
         }

        return result;
    }

    @Override
    public List<Element> read(int n, int timeout) {
        // TODO: TBD
        return EMPTY_RESULT;
    }

    @Override
    public void ack(List<Element> items) {
        items.forEach(item -> ack(item.getPageOffet()));
    }

    @Override
    public void ack(int offset) {
        this.unacked.remove(offset);
    }

    @Override
    public int unusedCount() {
        return readable().getCardinality();
    }

    @Override
    public int unackedCount() {
        return this.unacked.getCardinality();
    }

    @Override
    public boolean allUsed() {
        return readable().isEmpty();
    }

    @Override
    public boolean allAcked() {
        return this.unacked.isEmpty();
    }

    @Override
    public int capacity() {
        return this.capacity;
    }

    @Override
    public void setHead(int offset) {
        this.head = offset;
    }

    @Override
    public int getHead() {
        return this.head;
    }

    @Override
    public RoaringBitmap getUnacked() {
        return this.unacked;
    }

    @Override
    public void close() throws IOException {
        // TBD
    }

    public void resetUnused() {
        // reset unused bits to the state of the unacked bits
        this.unused = new RoaringBitmap(this.unacked.toMutableRoaringBitmap());
    }

    private int availableBytes() {
        return this.capacity - this.head;
    }

    private RoaringBitmap readable() {
        // select items that are both marked as unused and unacked
        return RoaringBitmap.and(this.unused, this.unacked);
    }

    private int totalBytes(int dataSize)
    {
        return OVERHEAD_BYTES + dataSize;
    }

    private int maxReadOffset() {
        return (this.head - (INT_BYTE_SIZE + 2));
    }

    // find the head of an existing byte buffer by looking from the beginning and skipping over items
    // until the last one
    // @param data a properly formatted byte buffer
    // @return int the discovered page head offset
    private static int findHead(ByteBuffer data) {
        int offset = 0;
        int dataSize;

        do {
            data.position(offset);

            dataSize = data.getInt();
            if (dataSize > 0) {
                offset += INT_BYTE_SIZE + dataSize;
            }
        } while (dataSize > 0);

        return offset;
    }
}

