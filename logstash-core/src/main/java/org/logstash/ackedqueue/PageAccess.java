package org.logstash.ackedqueue;

import java.io.IOException;

public abstract class PageAccess {
    final protected Page page;

    public PageAccess(Page page) {
        this.page = page;
    }

    public SequencedList<byte[]> read(int limit) throws IOException {
        // first make sure this page is activated, activating previously activated is harmless
        this.page.pageIO.activate();

        SequencedList<byte[]> serialized = this.page.pageIO.read(this.page.firstUnreadSeqNum, limit);
        assert serialized.getSeqNums().get(0) == this.page.firstUnreadSeqNum :
                String.format("firstUnreadSeqNum=%d != first result seqNum=%d", this.page.firstUnreadSeqNum, serialized.getSeqNums().get(0));

        this.page.firstUnreadSeqNum += serialized.getElements().size();

        return serialized;
    }

    public abstract void write(byte[] bytes, long seqNum, int checkpointMaxWrites) throws IOException;
    public abstract void checkpoint() throws IOException;
    public abstract void forceCheckpoint() throws IOException;
    public abstract void close() throws IOException;
    public abstract void purge() throws IOException;
    public abstract boolean hasSpace(int byteSize);
    public abstract boolean hasCapacity(int byteSize);
    public abstract void ensurePersistedUpto(long seqNum) throws IOException;
}
