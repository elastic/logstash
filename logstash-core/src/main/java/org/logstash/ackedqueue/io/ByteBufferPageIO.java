package org.logstash.ackedqueue.io;

import java.io.IOException;
import java.nio.ByteBuffer;

public class ByteBufferPageIO extends AbstractByteBufferPageIO {

    private final ByteBuffer buffer;

    public ByteBufferPageIO(int pageNum, int capacity, String path) throws IOException {
        this(capacity, new byte[0]);
    }

    public ByteBufferPageIO(int capacity) throws IOException {
        this(capacity, new byte[0]);
    }

    public ByteBufferPageIO(int capacity, byte[] initialBytes) throws IOException {
        super(0, capacity);

        if (initialBytes.length > capacity) {
            throw new IOException("initial bytes greater than capacity");
        }

        this.buffer = ByteBuffer.allocate(capacity);
        this.buffer.put(initialBytes);
    }

    @Override
    public void deactivate() { /* nothing */ }

    @Override
    public void activate() { /* nyet */ }

    @Override
    public void ensurePersisted() { /* nada */ }

    @Override
    public void purge() { /* zilch */ }

    @Override
    public void close() { /* don't look here */ }


    @Override
    protected ByteBuffer getBuffer() { return this.buffer; }

    // below public methods only used by tests

    public int getWritePosition() { return this.head; }

    public byte[] dump() { return this.buffer.array(); }
}
