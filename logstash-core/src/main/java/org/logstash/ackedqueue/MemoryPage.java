package org.logstash.ackedqueue;

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
    private int index;    // this page index number

    private PageState pageState;

    // @param capacity page byte size
    public MemoryPage(int capacity) {
        this(capacity, 0);
    }

    // @param capacity page byte size
    // @param index the page index number
    public MemoryPage(int capacity, int index) {
        this(capacity, index, ByteBuffer.allocate(capacity), EMPTY_PAGE_HEAD, new PageState());
    }

    // @param capacity page byte size
    // @param index the page index number
    // @param data initial data for this page
    // @param head the page head offset, @see MemoryPage.findHead() if it needs to be resolved
    // @param pageState initial page acking state state
    public MemoryPage(int capacity, int index, ByteBuffer data, int head, PageState pageState) {
        this.capacity = capacity;
        this.index = index;
        this.data = data;
        this.head = head;
        this.pageState = pageState;
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

        this.pageState.add(this.head);

        this.head += totalBytes(data.length);

        return this.head;
   }

    @Override
    public boolean writable(int bytes) {
        return (availableBytes() >= totalBytes(bytes));
    }

    @Override
    public Element read() {
        int offset = this.pageState.next();
        if (offset == PageState.EMPTY) {
            return null;
        }

        this.data.position(offset);

        int dataSize = this.data.getInt();
        assert dataSize > 0;

        byte[] payload = new byte[dataSize];;
        this.data.get(payload);

        this.pageState.setInuse(offset);

        return new Element(payload, this.index, offset);
    }

    // non-blocking read up to next n unusued item and mark them as in-use. if less than n items are available
    // these will be read and returned immediately.
    // @param n the requested number of items
    // @return List of read Element, or empty list if no items are read
    @Override
    public List<Element> read(int n) {

        // empty result optimization
        if (this.pageState.unusedCount() <= 0) {
            return EMPTY_RESULT;
        }

        List<Element> result = new ArrayList<>();

        Iterator i = this.pageState.batch(n);
        while (i.hasNext()) {
            int offset = (int) i.next();

            this.data.position(offset);

            int dataSize = this.data.getInt();
            assert dataSize > 0;

            byte[] payload = new byte[dataSize];;
            this.data.get(payload);

            // TODO: how/where should we track page index?
            result.add(new Element(payload, this.index, offset));

            this.pageState.setInuse(offset);
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
        this.pageState.setAcked(offset);
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
    public int getIndex() {
        return this.index;
    }

    @Override
    public PageState getPageState() {
        return this.pageState;
    }

    @Override
    public void close() throws IOException {
        // TBD
    }

    private int availableBytes() {
        return this.capacity - this.head;
    }

    private int totalBytes(int dataSize)
    {
        return OVERHEAD_BYTES + dataSize;
    }

//    private int maxReadOffset() {
//        return (this.head - (INT_BYTE_SIZE + 2));
//    }

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

