package org.logstash.ackedqueue;

import java.util.ArrayList;
import java.util.List;

public class MemoryElementStream {
    private final long byteSize;

    public MemoryElementStream(long byteSize) {
        this(byteSize, new byte[]{});
    }

    public MemoryElementStream(long byteSize, byte[] initialBytes) {
        this.byteSize = byteSize;
        // TODO: do something with initialBytes
        // TODO: scan and reconstruct seqNum->offset map
    }

    public List<Long> getOffsetMap() {
        return null;
    }

    public boolean hasSpace(int byteSize) {
        return true;
    }

    public long write(byte[] bytes, Queueable element) {
        return 0;
    }

    public List<byte[]> read(long startOffset, int limit) {
        return new ArrayList<>();
    }
}
