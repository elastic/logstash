package org.logstash.common.io;

import org.logstash.ackedqueue.Queueable;
import org.logstash.ackedqueue.SequencedList;
import sun.reflect.generics.reflectiveObjects.NotImplementedException;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.CRC32;
import java.util.zip.Checksum;

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
    public void activate() { /* niet */ }

    @Override
    public void ensurePersisted() { /* nada */ }

    @Override
    public void purge() { /* zilch */ }

    @Override
    public void close() { /* don't look here */ }


    @Override
    protected ByteBuffer getBuffer() { return this.buffer; }

    // below public methods only used by tests

    // TODO: static method for tests - should refactor
    public static int _persistedByteCount(int byteCount) { return SEQNUM_SIZE + LENGTH_SIZE + byteCount + CHECKSUM_SIZE; }

    public int getWritePosition() { return this.head; }

    public byte[] dump() { return this.buffer.array(); }
}
